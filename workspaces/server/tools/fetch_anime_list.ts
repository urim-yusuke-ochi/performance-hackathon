/* eslint-disable @typescript-eslint/no-non-null-assertion */
import JSZip from 'jszip';

interface Content<T extends 'episode' | 'series'> {
  '@type': T;
  title: string;
}

export async function fetchAnimeList(): Promise<{
  episode: Content<'episode'>[];
  series: Content<'series'>[];
}> {
  const zipBinary = await fetch(
    'https://github.com/mediaarts-db/dataset/raw/refs/tags/1.2/data/json-ld/metadata_an-col_an207_json.zip',
  ).then((r) => r.arrayBuffer());

  const zip = await JSZip.loadAsync(zipBinary);
  const file = zip.file('metadata_an-col_an207_00001.json')!;

  const json = JSON.parse(await file.async('text')) as Record<string, unknown>;
  const episodeList: Content<'episode'>[] = [];
  const seriesList: Content<'series'>[] = [];

  for (const record of json['@graph'] as Record<string, unknown>[]) {
    if (record['@type'] === 'class:AnimationTVRegularSeries' && typeof record['label'] === 'string') {
      seriesList.push({
        '@type': 'series',
        title: record['label'],
      });
      continue;
    }

    if (typeof record['alternativeHeadline'] === 'string') {
      episodeList.push({
        '@type': 'episode',
        title: record['alternativeHeadline'].replace(/第\p{N}+話\s*/u, ''),
      });
    }
  }

  return {
    episode: episodeList,
    series: seriesList,
  };
}
