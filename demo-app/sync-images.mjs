import { cp, mkdir, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const sourceDir = path.join(projectRoot, 'project', 'img');
const targetDir = path.join(__dirname, 'public', 'img');
const manifestFile = path.join(__dirname, 'src', 'data', 'imageManifest.json');

async function main() {
  await mkdir(targetDir, { recursive: true });

  const entries = await readdir(sourceDir, { withFileTypes: true });
  const imageFiles = entries.filter((entry) => entry.isFile());

  let copiedCount = 0;
  const fileNames = [];
  for (const entry of imageFiles) {
    const sourceFile = path.join(sourceDir, entry.name);
    const targetFile = path.join(targetDir, entry.name);
    await cp(sourceFile, targetFile, { force: true });
    copiedCount += 1;
    fileNames.push(entry.name);
  }

  await writeFile(manifestFile, `${JSON.stringify(fileNames.sort((a, b) => a.localeCompare(b)), null, 2)}\n`, 'utf-8');

  console.log(`已同步 ${copiedCount} 个素材到 demo-app/public/img，并生成图片清单`);
}

main().catch((error) => {
  console.error('同步图片失败：', error);
  process.exitCode = 1;
});
