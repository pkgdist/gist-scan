	// generate_version.ts
    const configRaw = await Deno.readTextFile("./deno.json");
    const config = JSON.parse(configRaw);
    const version = config.version ?? "v0.0.0"; // Default fallback if not found

    const versionFileContent = `
    // This file is auto-generated. Do not edit.
    export const generatedVersion = "${version}";
    `;

    await Deno.writeTextFile("./version.ts", versionFileContent);
    console.log(`Version file generated with version: ${version}`);
