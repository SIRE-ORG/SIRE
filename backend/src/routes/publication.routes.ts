import type { FastifyInstance } from 'fastify';
import { getPublications, getMyPublications, createPublication } from '../controllers/publication.controller.js';

export async function publicationRoutes(app: FastifyInstance) {
    app.get('/publications', getPublications);
    app.get('/publications/mine', getMyPublications);
    app.post('/publications', createPublication);
}