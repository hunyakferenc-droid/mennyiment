/* Shared real-browser verification, pinned to the 2.2.6 developer build. */
process.env.MENTI_EXPECTED_VERSION = '2.2.6';
process.env.MENTI_EXPECTED_BUILD = '29';
require('./verify_geometry_225_chrome.cjs');
