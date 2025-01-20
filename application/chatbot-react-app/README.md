# Chatbot React App

This project is a React-based chatbot application designed to provide product recommendations based on Microsoft Store URLs. The application features an animated background in the Microsoft "Glass" style and a user-friendly chat interface.

## Project Structure

```
chatbot-react-app
├── public
│   ├── index.html          # Main HTML file
│   └── styles.css         # Global styles
├── src
│   ├── components
│   │   ├── AnimatedBackground.tsx  # Animated background component
│   │   ├── ChatWindow.tsx          # Chat window component
│   │   └── App.tsx                 # Main application component
│   ├── App.css                    # Styles for the App component
│   ├── App.tsx                     # Entry point for the App component
│   ├── index.tsx                   # React application entry point
│   └── setupProxy.js               # Proxy setup for API requests
├── Dockerfile                       # Dockerfile for building the application
├── kubernetes
│   └── deployment.yaml              # Kubernetes deployment manifest
├── package.json                     # npm configuration file
├── tsconfig.json                    # TypeScript configuration file
└── README.md                        # Project documentation
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd chatbot-react-app
   ```

2. **Install dependencies:**
   ```
   npm install
   ```

3. **Run the application:**
   ```
   npm start
   ```

4. **Build the Docker image:**
   ```
   docker build -t chatbot-react-app .
   ```

5. **Deploy to Kubernetes:**
   - Ensure you have a Kubernetes cluster running.
   - Apply the deployment manifest:
     ```
     kubectl apply -f kubernetes/deployment.yaml
     ```

## Usage

- Open the application in your browser.
- Enter a Microsoft Store URL in the chat window to receive product recommendations.

## Environment Variables

- The application requires the LLM endpoint to be set as an environment variable in the Kubernetes deployment manifest. Ensure to replace the placeholder with the actual service IP address of the inference server.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.