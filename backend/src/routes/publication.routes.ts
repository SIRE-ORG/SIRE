import type { FastifyInstance } from 'fastify';
import { getPublications, getMyPublications, createPublication } from '../controllers/publication.controller.js';

export async function publicationRoutes(app: FastifyInstance) {
    app.get('/', getPublications);
    app.get('/mine', getMyPublications);
    app.post('/', createPublication);
}