import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Structured suggestion form — opens Mail with a pre-filled message to the developer.
struct FeedbackFormView: View {
    @Environment(\.openURL) private var openURL

    @State private var category: FeedbackCategory = .improvement
    @State private var specificItem = ""
    @State private var summary = ""
    @State private var details = ""
    @State private var showMailSheet = false
    @State private var showMailUnavailable = false

    private var draft: FeedbackDraft {
        FeedbackDraft(
            category: category,
            specificItem: specificItem,
            summary: summary,
            details: details
        )
    }

    var body: some View {
        Form {
            Section {
                Text(L10n.feedbackIntro)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Picker(L10n.feedbackCategoryPicker, selection: $category) {
                    ForEach(FeedbackCategory.allCases) { option in
                        Label(option.label, systemImage: option.systemImage).tag(option)
                    }
                }
            } header: {
                Text(L10n.feedbackCategoryTitle)
            }

            Section {
                TextField(
                    category.specificItemLabel,
                    text: $specificItem,
                    prompt: Text(category.specificItemPlaceholder)
                )
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("feedback.specificItem")
                TextField(
                    L10n.feedbackSummary,
                    text: $summary,
                    prompt: Text(category.summaryPlaceholder)
                )
                .textInputAutocapitalization(.sentences)
                .accessibilityIdentifier("feedback.summary")
            } header: {
                Text(L10n.feedbackSuggestionTitle)
            } footer: {
                Text(L10n.feedbackSummaryFooter)
            }

            Section {
                TextField(
                    L10n.feedbackDetailsField,
                    text: $details,
                    prompt: Text(category.detailsPlaceholder),
                    axis: .vertical
                )
                .lineLimit(4...12)
                .accessibilityIdentifier("feedback.details")
            } header: {
                Text(L10n.feedbackDetailsTitle)
            } footer: {
                Text(category.detailsPlaceholder)
            }

            Section {
                Button {
                    sendFeedback()
                } label: {
                    Label(L10n.feedbackSend, systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!draft.isValid)
                .accessibilityIdentifier("feedback.send")
            } footer: {
                Text(L10n.feedbackSendFooter)
            }
        }
        .navigationTitle(L10n.feedbackNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .tabRootScrollChrome()
        #if canImport(MessageUI)
        .sheet(isPresented: $showMailSheet) {
            MailComposeView(
                recipients: [AppSupport.feedbackEmail],
                subject: AppSupport.mailSubject(for: draft),
                body: AppSupport.mailBody(for: draft)
            ) {
                showMailSheet = false
            }
        }
        #endif
        .alert(L10n.feedbackMailUnavailableTitle, isPresented: $showMailUnavailable) {
            Button(L10n.feedbackMailUnavailableCopy) {
                #if canImport(UIKit)
                UIPasteboard.general.string = AppSupport.mailBody(for: draft)
                #endif
            }
            Button(L10n.feedbackMailUnavailableOpenMail) {
                openURL(AppSupport.mailtoURL(for: draft))
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.format("feedback.mailUnavailable.message", AppSupport.feedbackEmail))
        }
    }

    private func sendFeedback() {
        guard draft.isValid else { return }
        if AppSupport.canSendMail {
            showMailSheet = true
        } else {
            showMailUnavailable = true
        }
    }
}
