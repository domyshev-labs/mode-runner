import React, { useEffect, useState } from 'react';
import demo from '../demo.json';
import { fetchRecords } from '../../shared/api.mjs';

export default function App() {
  const [topic, setTopic] = useState(demo.defaultScenario);
  const [query, setQuery] = useState('');
  const [revision, setRevision] = useState(0);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const live = import.meta.env.MODE === 'live';
  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError('');
    setResult(null);
    fetchRecords(demo.id, live, topic, controller.signal)
      .then(setResult)
      .catch(error => { if (!controller.signal.aborted) setError(error.message); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [topic, revision]);
  const records = (result?.records ?? []).filter(record =>
    `${record.title} ${record.subtitle} ${record.description}`.toLowerCase().includes(query.toLowerCase()));
  const maxMagnitude = records.reduce((maximum, record) => Math.max(maximum, record.magnitude ?? 0), 0);
  return <main className={demo.id}>
    <header><a className="brand" href={demo.sourceURL} target="_blank" rel="noreferrer">SCIENCE / {demo.id === 'cosmic-archive' ? '01' : demo.id === 'mathematical-minds' ? '02' : '03'}</a>
      <span className={`badge ${live ? 'live' : ''}`}>{live ? 'Live API' : 'Mock data'}</span></header>
    <section className="intro"><p className="eyebrow">{demo.source}</p><h1>{demo.title}</h1><p>{demo.tagline}</p></section>
    <section className="toolbar" aria-label="Data controls">
      <div className="topics" aria-label="Topic">{live ? demo.scenarios.filter(scenario => !(demo.id === 'earth-observatory' && scenario.id === 'empty')).map(scenario => <button key={scenario.id} aria-pressed={topic === scenario.id} onClick={() => setTopic(scenario.id)}>{scenario.title}</button>) : <span>Choose a dataset from the Seeds menu in Mode Runner.</span>}</div>
      <label className="search"><span className="sr-only">Filter results</span><input placeholder="Filter results…" value={query} onChange={event => setQuery(event.target.value)} /></label>
      <button onClick={() => setRevision(value => value + 1)}>Refresh</button>
    </section>
    <div className="summary" aria-live="polite"><span>{loading ? 'Loading observations…' : `${records.length} ${demo.id === 'mathematical-minds' ? (records.length === 1 ? 'work' : 'works') : (records.length === 1 ? 'record' : 'records')}`}</span>
      {demo.id === 'earth-observatory' && records.length > 0 && <span>Maximum magnitude · {maxMagnitude.toFixed(1)}</span>}
      <span>{result ? `${live ? demo.source : `Seed: ${result.scenario}`} · updated ${new Date(result.updatedAt).toLocaleTimeString()}` : ''}</span></div>
    {error && <div className="notice" role="alert"><h2>Unable to load data</h2><p>{error}</p><button onClick={() => setRevision(value => value + 1)}>Try again</button></div>}
    {!loading && !error && records.length === 0 && <div className="notice"><h2>No records here yet</h2><p>{query ? 'Try another filter.' : 'Choose another topic or apply a different seed in Mode Runner, then refresh.'}</p></div>}
    <section className="grid" aria-label="Results">{records.map(record => <article key={record.id}>
      {demo.id !== 'earth-observatory' && <div className="visual"><span className="symbol" aria-hidden="true">{demo.id === 'cosmic-archive' ? '◉' : '∑'}</span>{record.image && <img src={record.image} alt={record.title} loading="lazy" onError={event => { event.currentTarget.style.display = 'none'; }} />}</div>}
      {record.magnitude != null && <div className="magnitude">{record.magnitude.toFixed(1)}<small>MAGNITUDE</small></div>}
      <div className="card-body"><p className="eyebrow">{record.subtitle}</p><h2>{record.title}</h2><p className="description">{record.description}</p><div className="card-footer"><span>{record.meta}</span>{record.url && <a href={record.url} target="_blank" rel="noreferrer">Explore ↗</a>}</div></div>
    </article>)}</section>
    <footer><span>Mode Runner / Independent React demo</span><span>{live ? 'Public API data. Availability depends on the provider.' : 'Offline demonstration fixtures. Apply a seed and refresh.'}</span></footer>
  </main>;
}
