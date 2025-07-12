useBash();

$.verbose = true

await $`./c3/c3c build`;
const luaFiles = await glob(['./resources/**/*.lua']);

for (const luaFile of luaFiles) {
  try {
    await $`./bin/luac -o out.luac ${luaFile}`;
    await $`./build/yue ./out.luac`;
    await $`rm -f out.luac`;
  } catch(e) {
    console.error(e)
  }
}