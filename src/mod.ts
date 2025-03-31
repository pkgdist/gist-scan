#!/usr/bin/env -S deno run --allow-net --allow-env
import { generatedVersion } from "./version.ts";
import { Command } from "jsr:@cliffy/command@^1.0.0-rc.7";
import { bold, red, yellow } from "jsr:@std/fmt@1/colors";
export { generatedVersion }
console.log("Current token:", Deno.env.get("GH_SCAN_TOKEN"));
export class GistScanner {
  private static SECRET_REGEX_STRING =
    "(gh[pousr]_[A-Za-z0-9_]{36,})|([A-Fa-f0-9]{32,64})|([A-Za-z0-9+/]{40,}=*)|(eyJ[A-Za-z0-9_=.-]+\.[A-Za-z0-9_=.-]+\.[A-Za-z0-9_=.-]+)|([A-Za-z0-9]{20,})";
  
  private headers = {
    "Authorization": `Bearer ${Deno.env.get("GH_SCAN_TOKEN")}`,
    "Accept": "application/vnd.github+json",
  };

  async fetchGists(): Promise<{ id: string; description?: string; files: { [key: string]: { filename: string; raw_url: string; content?: string } } }[]> {
    let page = 1;
    const allGists: { id: string; files: { [key: string]: { filename: string; raw_url: string; content?: string } } }[] = [];
    while (true) {
      const res = await fetch(`https://api.github.com/gists?per_page=10000000&page=${page}`, { headers: this.headers });
      if (!res.ok) throw new Error(`Failed to fetch gists: ${await res.text()}`);
      const gists = await res.json();
      if (gists.length === 0) break;
      allGists.push(...gists);
      page++;
    }
    return allGists;
  }

  private async getCustomCert(): Promise<string | undefined> {
    const certPath = Deno.env.get("DENO_CERT");
    if (certPath) {
      try {
        return await Deno.readTextFile(certPath);
      } catch (err) {
        if (err instanceof Error) {
          console.error(`Failed to read custom certificate from ${certPath}:`, err.message);
        } else {
          console.error(`Failed to read custom certificate from ${certPath}:`, String(err));
        }
      }
    }
    return undefined;
  }

  private async fetchWithCert(url: string, options: RequestInit): Promise<Response> {
    const customCert = await this.getCustomCert();
    if (customCert) {
      const client = Deno.createHttpClient({ caCerts: [customCert] });
      try {
        return await fetch(url, { ...options, client });
      } finally {
        client.close();
      }
    }
    return await fetch(url, options);
  }

  async getFileContents(gist: { id: string; files: { [key: string]: { filename: string; raw_url: string; content?: string } } }) {
    for (const file of Object.values<{ filename: string; raw_url: string; content?: string }>(gist.files)) {
      if (!file.content) {
        const res = await this.fetchWithCert(file.raw_url, { headers: this.headers });
        file.content = await res.text();
      }
  
      // Truncate content to 100 characters and clean up escaping
      if (file.content) {
        file.content = file.content.replace(/\\+/g, '').slice(0, 100) + (file.content.length > 100 ? '...' : '');
      }
    }
  }

  escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&');
  }

  highlightMatches(text: string, searchTerms: string[], regexTerms: string[]): string {
    let highlighted = text;
    for (const term of searchTerms) {
      const regex = new RegExp(`(${this.escapeRegex(term)})`, 'gi');
      highlighted = highlighted.replace(regex, yellow(bold('$1')));
    }
    for (const regStr of regexTerms) {
      const regex = new RegExp(regStr, 'gi');
      highlighted = highlighted.replace(regex, yellow(bold('$&')));
    }
    return highlighted;
  }

  matchesSearch(gist: { id: string; description?: string; files: { [key: string]: { filename: string; content?: string } } }, searchTerms: string[], regexTerms: string[]): boolean {
    const fieldsToSearch = [gist.description || "", ...Object.values<any>(gist.files).flatMap((file: any) => [file.filename, file.content || ""])];
    return fieldsToSearch.some(field =>
      searchTerms.some(term => field.includes(term)) ||
      regexTerms.some(regStr => new RegExp(regStr, 'i').test(field))
    );
  }

  async deleteGist(id: string) {
    const res = await fetch(`https://api.github.com/gists/${id}`, { method: "DELETE", headers: this.headers });
    if (res.status === 204) console.log(red(`Deleted gist: ${id}`));
    else console.error(`Failed to delete gist ${id}: ${await res.text()}`);
  }

  async run() {
    await new Command()
      .name("gist-scan")
      .version(`Verison: ${generatedVersion}`)
      .description("Scan your GitHub gists for secrets, regex, and terms.")
      .option("-t, --term <term:string>", "Search terms.", { collect: true })
      .option("-r, --regex <regex:string>", "Regex patterns.", { collect: true })
      .option("-s, --secrets", "Enable secret scanning.")
      .option("-d, --delete", "Delete matched gists.")
      .option("-y, --yes", "Auto-confirm deletions.")
      .action(async (opts) => { 
        const searchTerms = opts.term || [];
        const regexTerms = opts.regex || [];
        if (opts.secrets) regexTerms.push(GistScanner.SECRET_REGEX_STRING);
      
        if (!searchTerms.length && !regexTerms.length) {
          console.error(red("Error: You must provide --term, --regex, or --secrets."));
          Deno.exit(1);
        }
      
        console.log("Fetching gists...");
        const gists: { id: string; files: { [key: string]: { filename: string; raw_url: string; content?: string } } }[] = await this.fetchGists();
        const matches = [];
      
        for (const gist of gists) {
          await this.getFileContents(gist);
          if (this.matchesSearch(gist, searchTerms, regexTerms)) matches.push(gist);
        }
      
        if (!matches.length) return console.log(yellow("No gists matched your criteria."));
      
        console.log(bold(`\nFound ${matches.length} matching gist(s).`));
      
        for (const gist of matches) {
          console.log(bold(red("\n=== MATCH ===")));
          console.log(`ID: ${gist.id}`);
          
          for (const [filename, file] of Object.entries(gist.files)) {
            console.log(`File: ${this.highlightMatches(filename, searchTerms, regexTerms)}`);
            console.log(`Description: ${this.highlightMatches(file.content?.toString() || "", searchTerms, regexTerms)}`);
          }
      
          for (const file of Object.values<{ filename: string; raw_url: string; content?: string }>(gist.files)) {
            console.log(`File: ${this.highlightMatches(file.filename, searchTerms, regexTerms)}`);
            console.log(`Content:\n${this.highlightMatches(file.content || "", searchTerms, regexTerms)}\n`);
          }
          if (opts.delete && (opts.yes || prompt("Delete this gist? (y/n): ")?.toLowerCase() === "y")) {
            await this.deleteGist(gist.id);
          } else if (opts.delete) {
            console.log(yellow(`Skipped gist: ${gist.id}`));
          }
        }
      })
      .parse(Deno.args);
  }
}

if (import.meta.main) {
  const scanner = new GistScanner();
  await scanner.run();
}