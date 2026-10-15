export function normalizeRecords(id, data) {
  if (id === 'cosmic-archive') {
    if (!Array.isArray(data.collection?.items)) throw new Error('NASA returned an unexpected response.');
    return data.collection.items.filter(item => item.data?.[0]).map(item => {
      const entry = item.data[0];
      return { id: entry.nasa_id, title: entry.title, subtitle: entry.center ?? 'NASA',
        description: (entry.description ?? '').replace(/<[^>]*>/g, ''),
        meta: entry.date_created?.slice(0, 10), image: item.links?.find(link => link.rel === 'preview')?.href,
        url: `https://images.nasa.gov/details/${encodeURIComponent(entry.nasa_id)}` };
    });
  }
  if (id === 'mathematical-minds') {
    if (!Array.isArray(data.docs)) throw new Error('Open Library returned an unexpected response.');
    return data.docs.map(entry => ({ id: entry.key, title: entry.title,
      subtitle: entry.author_name?.join(', ') ?? 'Unknown author',
      description: `${entry.edition_count ?? 0} catalogued editions`,
      meta: entry.first_publish_year ? `First published ${entry.first_publish_year}` : 'Year unavailable',
      image: entry.cover_i ? `https://covers.openlibrary.org/b/id/${entry.cover_i}-M.jpg` : undefined,
      url: `https://openlibrary.org${entry.key}` }));
  }
  if (!Array.isArray(data.features)) throw new Error('USGS returned an unexpected response.');
  return data.features.slice(0, 24).map(entry => ({ id: entry.id,
    title: entry.properties.place ?? 'Unknown location', subtitle: 'Seismic observation',
    description: `Depth: ${entry.geometry.coordinates[2].toFixed(1)} km`,
    magnitude: entry.properties.mag ?? 0,
    meta: new Date(entry.properties.time).toLocaleString(), url: entry.properties.url }));
}

export async function fetchRecords(id, live, topic, signal) {
  const topics = { moon: 'moon', mars: 'mars', 'deep-space': 'galaxy',
    euler: 'Leonhard Euler', gauss: 'Carl Friedrich Gauss', noether: 'Emmy Noether' };
  let path = '/api/records';
  if (live) {
    if (id === 'cosmic-archive') path = `https://images-api.nasa.gov/search?q=${encodeURIComponent(topics[topic])}&media_type=image&page_size=12`;
    else if (id === 'mathematical-minds') path = `https://openlibrary.org/search.json?q=${encodeURIComponent(topics[topic])}&limit=12&fields=key,title,author_name,first_publish_year,cover_i,edition_count`;
    else path = `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/${topic === 'strong' ? '4.5_week' : 'all_day'}.geojson`;
  }
  const response = await fetch(path, { signal: AbortSignal.any([signal, AbortSignal.timeout(20000)]) });
  if (!response.ok) throw new Error(`Data request failed (${response.status}). ${live ? 'Try again later.' : 'Check that the mock server is running in Mode Runner.'}`);
  const data = await response.json();
  return live ? { records: normalizeRecords(id, data), updatedAt: new Date().toISOString() } : data;
}
