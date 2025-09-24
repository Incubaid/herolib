/**
 * Chat Widget JavaScript
 * Handles chat functionality, voice recording, and file management
 */

class ChatWidget {
    constructor() {
        this.messages = [];
        this.isRecording = false;
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.recordingStartTime = null;
        this.recordingTimer = null;
        this.selectedFiles = [];
        this.recordings = [];
        
        this.init();
    }

    init() {
        this.bindEvents();
        this.initializeRecorder();
        this.loadRecordings();
        this.setupContextMenu();
        this.autoResizeTextarea();
    }

    bindEvents() {
        // Chat input events
        const chatInput = document.getElementById('chatInput');
        const sendButton = document.getElementById('sendMessage');
        
        chatInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });
        
        chatInput.addEventListener('input', () => {
            this.autoResizeTextarea();
        });
        
        sendButton.addEventListener('click', () => {
            this.sendMessage();
        });

        // Voice input button
        document.getElementById('voiceInput').addEventListener('click', () => {
            this.toggleVoiceInput();
        });

        // File attachment
        document.getElementById('attachFile').addEventListener('click', () => {
            this.showFileUploadModal();
        });

        // Clear chat
        document.getElementById('clearChat').addEventListener('click', () => {
            this.clearChat();
        });

        // Recording controls
        document.getElementById('recordBtn').addEventListener('click', () => {
            this.startRecording();
        });

        document.getElementById('stopBtn').addEventListener('click', () => {
            this.stopRecording();
        });

        document.getElementById('playBtn').addEventListener('click', () => {
            this.playLastRecording();
        });

        // Explorer actions
        document.getElementById('newFolderBtn').addEventListener('click', () => {
            this.createNewFolder();
        });

        document.getElementById('refreshBtn').addEventListener('click', () => {
            this.refreshRecordings();
        });

        // File upload modal
        document.getElementById('uploadBtn').addEventListener('click', () => {
            this.uploadFile();
        });

        // Tree item clicks
        document.addEventListener('click', (e) => {
            if (e.target.closest('.tree-item-content')) {
                this.handleTreeItemClick(e);
            }
        });

        // Context menu
        document.addEventListener('contextmenu', (e) => {
            if (e.target.closest('.tree-item-content')) {
                e.preventDefault();
                this.showContextMenu(e);
            }
        });

        // Hide context menu on click outside
        document.addEventListener('click', () => {
            this.hideContextMenu();
        });
    }

    sendMessage() {
        const input = document.getElementById('chatInput');
        const message = input.value.trim();
        
        if (!message && this.selectedFiles.length === 0) return;

        // Add user message
        this.addMessage('user', message, this.selectedFiles);
        
        // Clear input and files
        input.value = '';
        this.selectedFiles = [];
        this.autoResizeTextarea();
        
        // Show typing indicator
        this.showTypingIndicator();
        
        // Simulate AI response (replace with actual API call)
        setTimeout(() => {
            this.hideTypingIndicator();
            this.addMessage('assistant', this.generateAIResponse(message));
        }, 1000 + Math.random() * 2000);
    }

    addMessage(sender, text, files = []) {
        const messagesContainer = document.getElementById('chatMessages');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.innerHTML = sender === 'user' ? '<i class="bi bi-person"></i>' : '<i class="bi bi-robot"></i>';
        
        const content = document.createElement('div');
        content.className = 'message-content';
        
        // Add file attachments if any
        if (files.length > 0) {
            files.forEach(file => {
                const fileDiv = document.createElement('div');
                fileDiv.className = 'file-attachment';
                fileDiv.innerHTML = `
                    <i class="bi bi-file-earmark file-attachment-icon"></i>
                    <div class="file-attachment-info">
                        <div class="file-attachment-name">${file.name}</div>
                        <div class="file-attachment-size">${this.formatFileSize(file.size)}</div>
                    </div>
                `;
                content.appendChild(fileDiv);
            });
        }
        
        if (text) {
            const textDiv = document.createElement('div');
            textDiv.className = 'message-text';
            textDiv.textContent = text;
            content.appendChild(textDiv);
        }
        
        const timeDiv = document.createElement('div');
        timeDiv.className = 'message-time';
        timeDiv.textContent = new Date().toLocaleTimeString();
        content.appendChild(timeDiv);
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(content);
        
        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
        
        this.messages.push({ sender, text, files, timestamp: new Date() });
    }

    showTypingIndicator() {
        const messagesContainer = document.getElementById('chatMessages');
        const typingDiv = document.createElement('div');
        typingDiv.className = 'message assistant typing-indicator';
        typingDiv.id = 'typingIndicator';
        typingDiv.innerHTML = `
            <div class="message-avatar">
                <i class="bi bi-robot"></i>
            </div>
            <div class="message-content">
                <div class="typing-indicator">
                    AI is typing
                    <div class="typing-dots">
                        <div class="typing-dot"></div>
                        <div class="typing-dot"></div>
                        <div class="typing-dot"></div>
                    </div>
                </div>
            </div>
        `;
        messagesContainer.appendChild(typingDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    hideTypingIndicator() {
        const typingIndicator = document.getElementById('typingIndicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }

    generateAIResponse(userMessage) {
        const responses = [
            "I understand your question. Let me help you with that.",
            "That's an interesting point. Here's what I think...",
            "Based on what you've shared, I'd suggest...",
            "I can help you with that. Here are some options...",
            "Thank you for the information. Let me process that...",
            "I see what you're asking. Here's my response..."
        ];
        return responses[Math.floor(Math.random() * responses.length)];
    }

    clearChat() {
        if (confirm('Are you sure you want to clear all messages?')) {
            document.getElementById('chatMessages').innerHTML = `
                <div class="message assistant">
                    <div class="message-avatar">
                        <i class="bi bi-robot"></i>
                    </div>
                    <div class="message-content">
                        <div class="message-text">Hello! I'm your AI assistant. How can I help you today?</div>
                        <div class="message-time">Just now</div>
                    </div>
                </div>
            `;
            this.messages = [];
        }
    }

    autoResizeTextarea() {
        const textarea = document.getElementById('chatInput');
        textarea.style.height = 'auto';
        textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
    }

    // Voice Recording Functions
    async initializeRecorder() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            this.mediaRecorder = new MediaRecorder(stream);
            
            this.mediaRecorder.ondataavailable = (event) => {
                this.audioChunks.push(event.data);
            };
            
            this.mediaRecorder.onstop = () => {
                this.saveRecording();
            };
            
        } catch (error) {
            console.error('Error accessing microphone:', error);
            this.showStatus('Microphone access denied', 'error');
        }
    }

    startRecording() {
        if (!this.mediaRecorder) {
            this.showStatus('Microphone not available', 'error');
            return;
        }

        this.audioChunks = [];
        this.mediaRecorder.start();
        this.isRecording = true;
        this.recordingStartTime = Date.now();
        
        // Update UI
        document.getElementById('recordBtn').disabled = true;
        document.getElementById('stopBtn').disabled = false;
        document.getElementById('recordingStatus').classList.add('active');
        
        // Start timer
        this.recordingTimer = setInterval(() => {
            this.updateRecordingTime();
        }, 1000);
        
        this.showStatus('Recording started...', 'success');
    }

    stopRecording() {
        if (!this.isRecording) return;
        
        this.mediaRecorder.stop();
        this.isRecording = false;
        
        // Update UI
        document.getElementById('recordBtn').disabled = false;
        document.getElementById('stopBtn').disabled = true;
        document.getElementById('playBtn').disabled = false;
        document.getElementById('recordingStatus').classList.remove('active');
        
        // Stop timer
        clearInterval(this.recordingTimer);
        
        this.showStatus('Recording stopped', 'success');
    }

    updateRecordingTime() {
        const elapsed = Math.floor((Date.now() - this.recordingStartTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        const timeString = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        document.querySelector('.recording-time').textContent = timeString;
    }

    saveRecording() {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/wav' });
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filename = `recording-${timestamp}.wav`;
        
        // Create download link (in real implementation, upload to server)
        const url = URL.createObjectURL(audioBlob);
        const recording = {
            name: filename,
            url: url,
            size: audioBlob.size,
            timestamp: new Date()
        };
        
        this.recordings.push(recording);
        this.updateRecordingsTree();
        this.showStatus(`Recording saved as ${filename}`, 'success');
    }

    playLastRecording() {
        if (this.recordings.length === 0) {
            this.showStatus('No recordings available', 'warning');
            return;
        }
        
        const lastRecording = this.recordings[this.recordings.length - 1];
        const audio = new Audio(lastRecording.url);
        audio.play();
        this.showStatus(`Playing ${lastRecording.name}`, 'info');
    }

    // File Management Functions
    showFileUploadModal() {
        const modal = new bootstrap.Modal(document.getElementById('fileUploadModal'));
        modal.show();
    }

    uploadFile() {
        const fileInput = document.getElementById('fileInput');
        const files = Array.from(fileInput.files);
        
        if (files.length === 0) return;
        
        // Simulate upload progress
        const progressContainer = document.getElementById('uploadProgress');
        const progressBar = progressContainer.querySelector('.progress-bar');
        
        progressContainer.style.display = 'block';
        
        let progress = 0;
        const interval = setInterval(() => {
            progress += Math.random() * 20;
            if (progress >= 100) {
                progress = 100;
                clearInterval(interval);
                
                // Add files to selected files
                this.selectedFiles = [...this.selectedFiles, ...files];
                this.showStatus(`${files.length} file(s) attached`, 'success');
                
                // Close modal
                bootstrap.Modal.getInstance(document.getElementById('fileUploadModal')).hide();
                progressContainer.style.display = 'none';
                progressBar.style.width = '0%';
                fileInput.value = '';
            }
            progressBar.style.width = progress + '%';
        }, 100);
    }

    // Tree and Context Menu Functions
    loadRecordings() {
        // Load sample recordings (replace with actual data loading)
        this.recordings = [
            { name: 'sample1.mp3', size: 2097152, timestamp: new Date() },
            { name: 'sample2.wav', size: 5242880, timestamp: new Date() }
        ];
        this.updateRecordingsTree();
    }

    updateRecordingsTree() {
        const tree = document.getElementById('explorerTree');
        const childrenContainer = tree.querySelector('.tree-item-children');
        
        // Clear existing items except samples
        childrenContainer.innerHTML = '';
        
        // Add recordings
        this.recordings.forEach(recording => {
            const item = document.createElement('div');
            item.className = 'tree-item file';
            item.dataset.path = `/${recording.name}`;
            item.innerHTML = `
                <div class="tree-item-content">
                    <i class="bi bi-file-earmark-music"></i>
                    <span class="tree-item-name">${recording.name}</span>
                    <span class="tree-item-size">${this.formatFileSize(recording.size)}</span>
                </div>
            `;
            childrenContainer.appendChild(item);
        });
    }

    handleTreeItemClick(e) {
        // Remove previous selection
        document.querySelectorAll('.tree-item-content.selected').forEach(item => {
            item.classList.remove('selected');
        });
        
        // Add selection to clicked item
        e.target.closest('.tree-item-content').classList.add('selected');
    }

    setupContextMenu() {
        const contextMenu = document.getElementById('contextMenu');
        
        contextMenu.addEventListener('click', (e) => {
            const action = e.target.dataset.action;
            if (action) {
                this.handleContextAction(action);
                this.hideContextMenu();
            }
        });
    }

    showContextMenu(e) {
        const contextMenu = document.getElementById('contextMenu');
        contextMenu.style.display = 'block';
        contextMenu.style.left = e.pageX + 'px';
        contextMenu.style.top = e.pageY + 'px';
    }

    hideContextMenu() {
        document.getElementById('contextMenu').style.display = 'none';
    }

    handleContextAction(action) {
        const selectedItem = document.querySelector('.tree-item-content.selected');
        if (!selectedItem) return;
        
        const filename = selectedItem.querySelector('.tree-item-name').textContent;
        
        switch (action) {
            case 'transcribe':
                this.showStatus(`Transcribing ${filename}...`, 'info');
                break;
            case 'translate':
                this.showStatus(`Translating ${filename}...`, 'info');
                break;
            case 'open':
                this.showStatus(`Opening ${filename}...`, 'info');
                break;
            case 'move':
                this.showStatus(`Moving ${filename}...`, 'info');
                break;
            case 'rename':
                this.renameFile(filename);
                break;
            case 'export':
                this.exportFile(filename);
                break;
        }
    }

    renameFile(oldName) {
        const newName = prompt('Enter new name:', oldName);
        if (newName && newName !== oldName) {
            this.showStatus(`Renamed ${oldName} to ${newName}`, 'success');
            // Update the recording name in the array and refresh tree
            const recording = this.recordings.find(r => r.name === oldName);
            if (recording) {
                recording.name = newName;
                this.updateRecordingsTree();
            }
        }
    }

    exportFile(filename) {
        const recording = this.recordings.find(r => r.name === filename);
        if (recording && recording.url) {
            const a = document.createElement('a');
            a.href = recording.url;
            a.download = filename;
            a.click();
            this.showStatus(`Exported ${filename}`, 'success');
        }
    }

    createNewFolder() {
        const folderName = prompt('Enter folder name:');
        if (folderName) {
            this.showStatus(`Created folder: ${folderName}`, 'success');
            // In real implementation, create folder in tree
        }
    }

    refreshRecordings() {
        this.showStatus('Refreshing recordings...', 'info');
        this.loadRecordings();
    }

    // Voice Input Functions
    toggleVoiceInput() {
        const button = document.getElementById('voiceInput');
        
        if (button.classList.contains('voice-input-active')) {
            this.stopVoiceInput();
        } else {
            this.startVoiceInput();
        }
    }

    startVoiceInput() {
        const button = document.getElementById('voiceInput');
        button.classList.add('voice-input-active');
        button.innerHTML = '<i class="bi bi-mic-fill"></i>';
        this.showStatus('Listening...', 'info');
        
        // Simulate voice recognition (replace with actual implementation)
        setTimeout(() => {
            this.stopVoiceInput();
            document.getElementById('chatInput').value = 'This is a voice input example';
            this.autoResizeTextarea();
        }, 3000);
    }

    stopVoiceInput() {
        const button = document.getElementById('voiceInput');
        button.classList.remove('voice-input-active');
        button.innerHTML = '<i class="bi bi-mic"></i>';
        this.showStatus('Voice input stopped', 'info');
    }

    // Utility Functions
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    showStatus(message, type = 'info') {
        const statusElement = document.getElementById('chatStatus');
        statusElement.textContent = message;
        statusElement.className = `chat-status text-${type === 'error' ? 'danger' : type === 'success' ? 'success' : type === 'warning' ? 'warning' : 'info'}`;
        
        // Clear status after 3 seconds
        setTimeout(() => {
            statusElement.textContent = '';
            statusElement.className = 'chat-status';
        }, 3000);
    }
}

// Initialize chat widget when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.chatWidget = new ChatWidget();
});

// Export for external use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ChatWidget;
}