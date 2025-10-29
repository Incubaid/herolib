#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openrouter
import incubaid.herolib.core.playcmds

// Sample code file to be improved
const sample_code = '
def calculate_sum(numbers):
    total = 0
    for i in range(len(numbers)):
        total = total + numbers[i]
    return total

def find_max(lst):
    max = lst[0]
    for i in range(1, len(lst)):
        if lst[i] > max:
            max = lst[i]
    return max
'

mut modifier := openrouter.get(name: 'modifier', create: true) or {
	panic('Failed to get modifier client: ${err}')
}

mut enhancer := openrouter.get(name: 'enhancer', create: true) or {
	panic('Failed to get enhancer client: ${err}')
}

println('═'.repeat(70))
println('🔧 Two-Model Code Enhancement Pipeline - Proof of Concept')
println('═'.repeat(70))
println('')

// Step 1: Get enhancement suggestions from Model A (Qwen3 Coder 480B)
println('📝 STEP 1: Code Enhancement Analysis')
println('─'.repeat(70))
println('Model: Qwen3 Coder 480B A35B')
println('Task: Analyze code and suggest improvements\n')

enhancement_prompt := 'You are a code enhancement agent.
Your job is to analyze the following Python code and propose improvements or fixes.
Output your response as **pure edits or diffs only**, not a full rewritten file.
Focus on:
- Performance improvements
- Pythonic idioms
- Bug fixes
- Code clarity

Here is the code to analyze:
${sample_code}

Provide specific edit instructions or diffs.'

println('🤖 Sending to enhancement model...')
enhancement_result := enhancer.chat_completion(
	message:               enhancement_prompt
	temperature:           0.3
	max_completion_tokens: 2000
) or {
	eprintln('❌ Enhancement failed: ${err}')
	return
}

println('\n✅ Enhancement suggestions received:')
println('─'.repeat(70))
println(enhancement_result.result)
println('─'.repeat(70))
println('Tokens used: ${enhancement_result.usage.total_tokens}\n')

// Step 2: Apply edits using Model B (morph-v3-fast)
println('\n📝 STEP 2: Apply Code Modifications')
println('─'.repeat(70))
println('Model: morph-v3-fast')
println('Task: Apply the suggested edits to produce updated code\n')

modification_prompt := 'You are a file editing agent.
Apply the given edits or diffs to the provided file.
Output the updated Python code only, without comments or explanations.

ORIGINAL CODE:
${sample_code}

EDITS TO APPLY:
${enhancement_result.result}

Output only the final, updated Python code.'

println('🤖 Sending to modification model...')
modification_result := modifier.chat_completion(
	message:               modification_prompt
	temperature:           0.1
	max_completion_tokens: 2000
) or {
	eprintln('❌ Modification failed: ${err}')
	return
}

println('\n✅ Modified code received:')
println('─'.repeat(70))
println(modification_result.result)
println('─'.repeat(70))
println('Tokens used: ${modification_result.usage.total_tokens}\n')

// Summary
println('\n📊 PIPELINE SUMMARY')
println('═'.repeat(70))
println('Original code length: ${sample_code.len} chars')
println('Enhancement model: qwen/qwq-32b-preview (Qwen3 Coder 480B A35B)')
println('Enhancement tokens: ${enhancement_result.usage.total_tokens}')
println('Modification model: neversleep/llama-3.3-70b-instruct (morph-v3-fast)')
println('Modification tokens: ${modification_result.usage.total_tokens}')
println('Total tokens: ${enhancement_result.usage.total_tokens +
	modification_result.usage.total_tokens}')
println('═'.repeat(70))
println('\n✅ Two-model pipeline completed successfully!')
