//
//  TutorialViewModel.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 14/12/25.
//


import SwiftUI
import Combine


@MainActor
final class TutorialViewModel: ObservableObject {

    

    enum Step {
        case goal
        case hudIntro
        case basics123
    }

    @Published var step: Step = .goal
    @Published var showGotIt = false

    func start() {
        showGotIt = false

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            step = .hudIntro

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showGotIt = true
        }
    }

    func gotIt() {
        showGotIt = false
        step = .basics123
        // qui dopo vediamo cosa succede
    }
}
