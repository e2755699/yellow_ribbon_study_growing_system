'use strict';
class Store {
  constructor(bucket) { this.bucket = bucket; }
  async read(name) {
    const file = this.bucket.file(name);
    for (let attempt = 0; attempt < 4; attempt++) {
      let metadata;
      try { [metadata] = await file.getMetadata(); }
      catch (e) { if (e.code === 404) return {value: null, generation: 0}; throw e; }
      try { const [bytes] = await this.bucket.file(name, {generation: metadata.generation}).download(); return {value: JSON.parse(bytes), generation: metadata.generation}; }
      catch (e) { if (e.code !== 404) throw e; } // Concurrent replacement: read the new generation.
    }
    throw new Error('Object changed during read');
  }
  async write(name, value, generation) {
    await this.bucket.file(name).save(JSON.stringify(value), {resumable: false, contentType: 'application/json', preconditionOpts: {ifGenerationMatch: generation}});
  }
  async update(name, fn) {
    for (let attempt = 0; attempt < 8; attempt++) {
      const old = await this.read(name); const value = fn(old.value);
      if (value === undefined) return old.value;
      try { await this.write(name, value, old.generation); return value; }
      catch (e) { if (e.code !== 412) throw e; }
    }
    throw new Error('Concurrent state updates did not settle');
  }
}
module.exports = {Store};
