// Product version. Defined once in desktop/package.json and injected at build time
// through REACT_APP_VERSION (see .env.development / .env.production). Never hard-code it elsewhere.
export const VERSION = process.env.REACT_APP_VERSION || 'dev';
