import { DurableObject } from 'cloudflare:workers';
import api, { type Env } from './api';

// 既存の Container DO を破壊せず更新するための互換 export。
// 新しい API はこの名前空間を呼ばない。旧コンテナの停止・削除は README に従い人が行う。
export class Backend extends DurableObject<Env> {}

export default api;
