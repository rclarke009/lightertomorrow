// Copyright © 2024 Apple Inc.

import AsyncAlgorithms
import MLX
import MLXLLM
import MLXLMCommon
import MarkdownUI
import Metal
import SwiftUI
import Tokenizers

struct ContentView: View {
    @Environment(DeviceStat.self) private var deviceStat

    @State var llm = LLMEvaluator()

    enum displayStyle: String, CaseIterable, Identifiable {
        case plain, markdown
        var id: Self { self }
    }

    @State private var selectedDisplayStyle = displayStyle.markdown

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text(llm.modelInfo)
                        .textFieldStyle(.roundedBorder)

                    Spacer()

                    Text(llm.stat)
                }
                HStack {
                    Toggle(isOn: $llm.includeWeatherTool) {
                        Text("Include tools")
                    }
                    .frame(maxWidth: 350, alignment: .leading)
                    Toggle(isOn: $llm.enableThinking) {
                        Text("Thinking")
                            .help(
                                "Switches between thinking and non-thinking modes. Support: Qwen3")
                    }
                    Spacer()
                    if llm.running {
                        ProgressView()
                            .frame(maxHeight: 20)
                        Spacer()
                    }
                    Picker("", selection: $selectedDisplayStyle) {
                        ForEach(displayStyle.allCases, id: \.self) { option in
                            Text(option.rawValue.capitalized)
                                .tag(option)
                        }

                    }
                    .pickerStyle(.segmented)
                    #if os(visionOS)
                        .frame(maxWidth: 250)
                    #else
                        .frame(maxWidth: 150)
                    #endif
                }
                
                // Token limit control
                HStack {
                    Text("Max Tokens:")
                        .frame(width: 100, alignment: .leading)
                    Slider(value: Binding(
                        get: { Double(llm.generateParameters.maxTokens ?? 1000) },
                        set: { llm.generateParameters.maxTokens = Int($0) }
                    ), in: 50...2000, step: 50)
                    Text("\(llm.generateParameters.maxTokens ?? 1000)")
                        .frame(width: 60, alignment: .trailing)
                        .font(.caption)
                    Spacer()
                }
            }

            // show the model output
            ScrollView(.vertical) {
                ScrollViewReader { sp in
                    Group {
                        if selectedDisplayStyle == .plain {
                            Text(llm.output)
                                .textSelection(.enabled)
                        } else {
                            Markdown(llm.output)
                                .textSelection(.enabled)
                        }
                    }
                    .onChange(of: llm.output) { _, _ in
                        sp.scrollTo("bottom")
                    }

                    Spacer()
                        .frame(width: 1, height: 1)
                        .id("bottom")
                }
            }

            HStack {
                TextField("prompt", text: Bindable(llm).prompt)
                    .onSubmit(generate)
                    .disabled(llm.running)
                    #if os(visionOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                Button(llm.running ? "stop" : "generate", action: llm.running ? cancel : generate)
                if !llm.output.isEmpty && !llm.running && llm.isIncompleteSentence(llm.output) {
                    Button("More") {
                        llm.continueGeneration()
                    }
                    .disabled(llm.running)
                }
            }
        }
        #if os(visionOS)
            .padding(40)
        #else
            .padding()
        #endif
        .toolbar {
            ToolbarItem {
                Label(
                    "Memory Usage: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))",
                    systemImage: "info.circle.fill"
                )
                .labelStyle(.titleAndIcon)
                .padding(.horizontal)
                .help(
                    Text(
                        """
                        Active Memory: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))/\(GPU.memoryLimit.formatted(.byteCount(style: .memory)))
                        Cache Memory: \(deviceStat.gpuUsage.cacheMemory.formatted(.byteCount(style: .memory)))/\(GPU.cacheLimit.formatted(.byteCount(style: .memory)))
                        Peak Memory: \(deviceStat.gpuUsage.peakMemory.formatted(.byteCount(style: .memory)))
                        """
                    )
                )
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        copyToClipboard(llm.output)
                    }
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc.fill")
                }
                .disabled(llm.output == "")
                .labelStyle(.titleAndIcon)
            }

        }
        .task {
            do {
                // pre-load the weights on launch to speed up the first generation
                _ = try await llm.load()
            } catch {
                llm.output = "Failed: \(error)"
            }
        }
    }

    private func generate() {
        llm.generate()
    }

    private func cancel() {
        llm.cancelGeneration()
    }

    private func copyToClipboard(_ string: String) {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
        #else
            UIPasteboard.general.string = string
        #endif
    }
}

@Observable
@MainActor
class LLMEvaluator {

    var running = false

    var includeWeatherTool = false
    var enableThinking = false

    var prompt = ""
    var output = ""
    var modelInfo = ""
    var stat = ""

    /// This controls which model loads. `qwen2_5_1_5b` is one of the smaller ones, so this will fit on
    /// more devices.
    let modelConfiguration = LLMRegistry.qwen3_1_7b_4bit

    /// parameters controlling the output
    var generateParameters = GenerateParameters(maxTokens: 1000, temperature: 0.6)
    let updateInterval = Duration.seconds(0.25)

    /// A task responsible for handling the generation process.
    var generationTask: Task<Void, Error>?

    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }

    var loadState = LoadState.idle

    let currentWeatherTool = Tool<WeatherInput, WeatherOutput>(
        name: "get_current_weather",
        description: "Get the current weather in a given location",
        parameters: [
            .required(
                "location", type: .string, description: "The city and state, e.g. San Francisco, CA"
            ),
            .optional(
                "unit",
                type: .string,
                description: "The unit of temperature",
                extraProperties: [
                    "enum": ["celsius", "fahrenheit"],
                    "default": "celsius",
                ]
            ),
        ]
    ) { input in
        let range = input.unit == "celsius" ? (min: -20.0, max: 40.0) : (min: 0, max: 100)
        let temperature = Double.random(in: range.min ... range.max)

        let conditions = ["Sunny", "Cloudy", "Rainy", "Snowy", "Windy", "Stormy"].randomElement()!

        return WeatherOutput(temperature: temperature, conditions: conditions)
    }

    let addTool = Tool<AddInput, AddOutput>(
        name: "add_two_numbers",
        description: "Add two numbers together",
        parameters: [
            .required("first", type: .int, description: "The first number to add"),
            .required("second", type: .int, description: "The second number to add"),
        ]
    ) { input in
        AddOutput(result: input.first + input.second)
    }

    let timeTool = Tool<EmptyInput, TimeOutput>(
        name: "get_time",
        description: "Get the current time",
        parameters: []
    ) { _ in
        TimeOutput(time: Date.now.formatted())
    }

    /// load and return the model -- can be called multiple times, subsequent calls will
    /// just return the loaded model
    func load() async throws -> ModelContainer {
        switch loadState {
        case .idle:
            // limit the buffer cache
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            let modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            ) {
                [modelConfiguration] progress in
                Task { @MainActor in
                    self.modelInfo =
                        "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
            }
            let numParams = await modelContainer.perform { context in
                context.model.numParameters()
            }

            self.prompt = modelConfiguration.defaultPrompt
            self.modelInfo =
                "Loaded \(modelConfiguration.id). Weights: \(numParams / (1024*1024))M"
            loadState = .loaded(modelContainer)
            return modelContainer

        case .loaded(let modelContainer):
            return modelContainer
        }
    }

    private func generate(prompt: String, toolResult: String? = nil, isContinuation: Bool = false) async {

        if !isContinuation {
            self.output = ""
        }
        
        var chat: [Chat.Message] = [
            .system("You are a helpful assistant"),
        ]
        
        if isContinuation {
            // For continuation, use the current output as the context
            chat.append(.user("Continue from where you left off. Complete any incomplete thoughts or sentences."))
            chat.append(.assistant(output))
        } else {
            chat.append(.user(prompt))
        }

        if let toolResult {
            chat.append(.tool(toolResult))
        }

        let userInput = UserInput(
            chat: chat,
            tools: includeWeatherTool
                ? [currentWeatherTool.schema, addTool.schema, timeTool.schema] : nil,
            additionalContext: ["enable_thinking": enableThinking]
        )

        do {
            let modelContainer = try await load()

            // each time you generate you will get something new
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            try await modelContainer.perform { (context: ModelContext) -> Void in
                let lmInput = try await context.processor.prepare(input: userInput)
                let stream = try await MLXLMCommon.generate(
                    input: lmInput, parameters: generateParameters, context: context)

                // generate and output in batches
                for await batch in stream._throttle(
                    for: updateInterval, reducing: Generation.collect)
                {
                    let output = batch.compactMap { $0.chunk }.joined(separator: "")
                    if !output.isEmpty {
                        Task { @MainActor [output] in
                            if isContinuation {
                                // For continuation, append to existing output
                                self.output += output
                            } else {
                                self.output += output
                            }
                        }
                    }

                    if let completion = batch.compactMap({ $0.info }).first {
                        Task { @MainActor in
                            self.stat = "\(completion.tokensPerSecond) tokens/s"
                        }
                    }

                    if let toolCall = batch.compactMap({ $0.toolCall }).first {
                        try await handleToolCall(toolCall, prompt: prompt)
                    }
                }
            }

        } catch {
            output = "Failed: \(error)"
        }
    }

    func generate() {
        guard !running else { return }
        let currentPrompt = prompt
        prompt = ""
        generationTask = Task {
            running = true
            await generate(prompt: currentPrompt)
            running = false
        }
    }
    
    func continueGeneration() {
        guard !running && !output.isEmpty else { return }
        generationTask = Task {
            running = true
            await generate(prompt: "", isContinuation: true)
            running = false
        }
    }
    
    func isIncompleteSentence(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Check if the text ends with incomplete punctuation or is cut off mid-word
        return !trimmed.isEmpty && 
               !trimmed.hasSuffix(".") && 
               !trimmed.hasSuffix("!") && 
               !trimmed.hasSuffix("?") && 
               !trimmed.hasSuffix(":") && 
               !trimmed.hasSuffix(";") &&
               !trimmed.hasSuffix(")") &&
               !trimmed.hasSuffix("]") &&
               !trimmed.hasSuffix("}")
    }

    func cancelGeneration() {
        generationTask?.cancel()
        running = false
    }

    private func handleToolCall(_ toolCall: ToolCall, prompt: String) async throws {
        let result =
            switch toolCall.function.name {
            case currentWeatherTool.name:
                try await toolCall.execute(with: currentWeatherTool).toolResult
            case addTool.name:
                try await toolCall.execute(with: addTool).toolResult
            case timeTool.name:
                try await toolCall.execute(with: timeTool).toolResult
            default:
                "No tool match"
            }

        await generate(prompt: prompt, toolResult: result)
    }
}

struct WeatherInput: Codable {
    let location: String
    let unit: String?
}

struct WeatherOutput: Codable {
    let temperature: Double
    let conditions: String
}

struct AddInput: Codable {
    let first: Int
    let second: Int
}

struct AddOutput: Codable {
    let result: Int
}

struct EmptyInput: Codable {}

struct TimeOutput: Codable {
    let time: String
}
