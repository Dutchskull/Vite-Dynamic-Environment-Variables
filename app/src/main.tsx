import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import environment from './environment'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <div>{environment.HELLO_WORLD}</div>
  </StrictMode>,
)
