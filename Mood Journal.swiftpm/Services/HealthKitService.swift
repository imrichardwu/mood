import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
final class HealthKitManager: ObservableObject {
    enum AuthState: Equatable {
        case unavailable
        case notDetermined
        case denied
        case authorized
    }

    @Published private(set) var authState: AuthState = .unavailable
    @Published private(set) var todaySteps: Double?
    @Published private(set) var lastNightSleepHours: Double?
    @Published private(set) var lastErrorMessage: String?

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    init() {
        refreshAuthState()
    }

    func refreshAuthState() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            authState = .unavailable
            return
        }

        let readTypes = Self.readTypes
        // Use steps as the representative authorization status.
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            switch store.authorizationStatus(for: stepType) {
            case .notDetermined: authState = .notDetermined
            case .sharingDenied: authState = .denied
            case .sharingAuthorized: authState = .authorized
            @unknown default: authState = .notDetermined
            }
        } else if !readTypes.isEmpty {
            authState = .notDetermined
        } else {
            authState = .unavailable
        }
        #else
        authState = .unavailable
        #endif
    }

    func requestAuthorization() async {
        lastErrorMessage = nil

        #if canImport(HealthKit)
        // If the Info.plist usage strings are missing, iOS can terminate the app on requestAuthorization.
        // Some Swift Playgrounds/SwiftPM templates do not expose Info.plist customization via Package.swift.
        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil else {
            lastErrorMessage = "HealthKit needs NSHealthShareUsageDescription in Info.plist. Add it in Xcode Target settings, then try again."
            authState = .unavailable
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            authState = .unavailable
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
            refreshAuthState()
        } catch {
            lastErrorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
            refreshAuthState()
        }
        #else
        authState = .unavailable
        #endif
    }

    func refreshToday() async {
        lastErrorMessage = nil
        refreshAuthState()

        guard authState == .authorized else { return }

        #if canImport(HealthKit)
        do {
            todaySteps = try await fetchTodaySteps()
            lastNightSleepHours = try await fetchLastNightSleepHours()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    #if canImport(HealthKit)
    private static var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(steps) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { set.insert(sleep) }
        return set
    }

    private func fetchTodaySteps() async throws -> Double? {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error { cont.resume(throwing: error); return }
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count())
                cont.resume(returning: steps)
            }
            store.execute(query)
        }
    }

    private func fetchLastNightSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        // Best-effort: look back 36h and sum "asleep" samples.
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -36, to: end) ?? end.addingTimeInterval(-36 * 3600)

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let catSamples = (samples as? [HKCategorySample]) ?? []

                // Include "asleep" categories. Apple has multiple values across iOS versions.
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let asleepSeconds = catSamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let hours = asleepSeconds / 3600.0
                cont.resume(returning: hours > 0 ? hours : nil)
            }
            store.execute(query)
        }
    }
    #endif
}


