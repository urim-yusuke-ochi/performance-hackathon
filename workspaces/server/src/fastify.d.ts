import 'fastify';

declare module 'fastify' {
  interface Session {
    id?: string;
  }
}
