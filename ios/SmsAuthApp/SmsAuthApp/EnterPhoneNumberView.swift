//
//  EnterPhoneNumberView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI
import PhoneNumberKit

struct EnterPhoneNumberView: View {
    @ObservedObject var userService: UserService
    @Binding var showVerifyCode: Bool

    @State private var phoneNumber = ""
    @State private var selectedRegion = "US"
    @State private var partialFormatter = PartialFormatter(defaultRegion: "US")

    private let phoneNumberUtility = PhoneNumberUtility()
    private let supportedRegions = ["US", "MX", "CA", "IN", "CN"]

    private var regionFlag: String {
        let base: UInt32 = 127397
        return selectedRegion.unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }

    private var countryCode: String {
        let code = phoneNumberUtility.countryCode(for: selectedRegion) ?? 1
        return "+\(code)"
    }

    private var formattedPhoneNumber: String {
        guard !phoneNumber.isEmpty else { return "" }
        let fullNumber = "\(countryCode)\(phoneNumber)"
        do {
            let parsed = try phoneNumberUtility.parse(fullNumber, withRegion: selectedRegion)
            return phoneNumberUtility.format(parsed, toType: .national)
        } catch {
            return phoneNumber
        }
    }

    private var e164PhoneNumber: String? {
        let fullNumber = "\(countryCode)\(phoneNumber)"
        do {
            let parsed = try phoneNumberUtility.parse(fullNumber, withRegion: selectedRegion)
            return phoneNumberUtility.format(parsed, toType: .e164)
        } catch {
            return nil
        }
    }

    private var isValidPhoneNumber: Bool {
        e164PhoneNumber != nil
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What's your phone number?")
                .font(.title)
                .fontWeight(.bold)

            Text("We'll text you a code to verify your phone")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Phone entry row
            HStack(spacing: 12) {
                // Flag and country code selector
                Menu {
                    ForEach(supportedRegions, id: \.self) { region in
                        Button {
                            selectedRegion = region
                            partialFormatter = PartialFormatter(defaultRegion: region)
                            phoneNumber = partialFormatter.formatPartial(phoneNumber)
                            userService.clearAuthError()
                        } label: {
                            let code = phoneNumberUtility.countryCode(for: region) ?? 0
                            Text("\(flagForRegion(region)) +\(code)")
                        }
                    }
                } label: {
                    HStack {
                        Text(regionFlag)
                            .font(.title2)
                        Text(countryCode)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Phone number text field
                TextField("Phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: phoneNumber) { oldValue, newValue in
                        userService.clearAuthError()
                        let formatted = partialFormatter.formatPartial(newValue)
                        if formatted != newValue {
                            phoneNumber = formatted
                        }
                    }
            }
            .padding(.horizontal)

            // Error text
            if let error = userService.authError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Spacer()

            // Next button
            Button {
                Task {
                    if let e164 = e164PhoneNumber {
                        await userService.sendVerificationCode(phoneNumber: e164)
                        if userService.authError == nil {
                            showVerifyCode = true
                        }
                    }
                }
            } label: {
                Group {
                    if userService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Next")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidPhoneNumber ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidPhoneNumber || userService.isLoading)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func flagForRegion(_ region: String) -> String {
        let base: UInt32 = 127397
        return region.unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }
}

#Preview {
    EnterPhoneNumberView(
        userService: UserService(),
        showVerifyCode: .constant(false)
    )
}
