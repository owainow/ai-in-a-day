import React from 'react';
import AnimatedBackground from './AnimatedBackground';
import ChatWindow from './ChatWindow';

interface AppProps {
  llmEndpoint: string;
}

const App: React.FC<AppProps> = ({ llmEndpoint }) => {
  return (
    <div className="app">
      <AnimatedBackground />
      <h1 className="title">Microsoft Store Assistant</h1>
      <ChatWindow llmEndpoint={llmEndpoint} />
    </div>
  );
};

export default App;