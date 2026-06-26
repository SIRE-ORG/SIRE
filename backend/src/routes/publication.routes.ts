import type { FastifyInstance } from 'fastify';
import {
    getPublications,
    getMyPublications,
    createPublication,
    getPublicationById,
    updatePublication,
    deletePublication
} from '../controllers/publication.controller.js';

export async function publicationRoutes(app: FastifyInstance) {
    app.get('/publications', getPublications);
    app.get('/publications/mine', getMyPublications);
    app.post('/publications', createPublication);

    app.get('/:id', getPublicationById);
    app.put('/:id', updatePublication);
    app.delete('/:id', deletePublication);

}