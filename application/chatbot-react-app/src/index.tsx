import React from 'react';
import ReactDOM from 'react-dom';
import App from './components/App';
import './App.css';

const LLM_ENDPOINT = process.env.REACT_APP_LLM_ENDPOINT || 'http://localhost:5000';

ReactDOM.render(
  <React.StrictMode>
    <App llmEndpoint={LLM_ENDPOINT} />
  </React.StrictMode>,
  document.getElementById('root')
);