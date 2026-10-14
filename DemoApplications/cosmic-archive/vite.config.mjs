import { createDemoConfig } from '../shared/vite-config.mjs';
import demo from './demo.json' with { type: 'json' };
export default ({ mode }) => createDemoConfig(demo, mode);
