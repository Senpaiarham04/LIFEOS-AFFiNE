import fs from 'node:fs';
import path from 'node:path';

const tag = process.argv[2] || 'local-dev';
const ver = tag.replace(/^v/, '');
const root = path.resolve(import.meta.dirname, '..');

const rootPkgPath = path.join(root, 'package.json');
const electronPkgPath = path.join(root, 'packages/frontend/apps/electron/package.json');

const rootPkg = JSON.parse(fs.readFileSync(rootPkgPath, 'utf-8'));
const electronPkg = JSON.parse(fs.readFileSync(electronPkgPath, 'utf-8'));

rootPkg.version = ver;
electronPkg.version = ver;

fs.writeFileSync(rootPkgPath, JSON.stringify(rootPkg, null, 2) + '\n');
fs.writeFileSync(electronPkgPath, JSON.stringify(electronPkg, null, 2) + '\n');

console.log(`Version set to ${ver} (root + electron)`);
