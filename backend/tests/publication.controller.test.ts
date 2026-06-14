import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
    getPublications,
    getMyPublications,
    createPublication,
    getPublicationById,
    updatePublication,
    deletePublication
} from '../src/controllers/publication.controller';

const prismaMock = vi.hoisted(() => ({
    publication: {
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
    },
    profile: {
        findUnique: vi.fn(),
    }
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: class { constructor() { return prismaMock; } },
    AccountStatus: { guest: 'guest', active: 'active' }
}));

describe('Módulo 2: Publicaciones', () => {
    let mockRequest: any;
    let mockReply: any;

    beforeEach(() => {
        vi.clearAllMocks();
        mockRequest = { body: {}, params: {}, query: {}, headers: { 'x-user-id': 'dueño-1' } };
        mockReply = {
            status: vi.fn().mockReturnThis(),
            send: vi.fn()
        };
    });

    //GET /publications
    it('Feed Público: Debería retornar todas las publicaciones con estado 200', async () => {
        prismaMock.publication.findMany.mockResolvedValue([{ id: 'pub-1', title: 'Cancha Central' }]);

        await getPublications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    //GET /publications/mine
    it('Mis Publicaciones: Debería bloquear con 400 si falta el header x-user-id', async () => {
        mockRequest.headers = {};
        await getMyPublications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    //POST /publications
    it('Creación: Debería crear la publicación (201) si pasa todas las validaciones y es ACTIVE', async () => {
        mockRequest.body = {
            title: 'Nueva Cancha', description: 'Techada', category: 'DEPORTE',
            imageUrl: 'url', region: 'RM', city: 'Santiago', availability: true, ownerId: 'dueño-1'
        };
        prismaMock.profile.findUnique.mockResolvedValue({ id: 'dueño-1', accountStatus: 'active' });
        prismaMock.publication.create.mockResolvedValue({ id: 'pub-new' });

        await createPublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(201);
    });

    it('Creación: Debería rechazar (400) si faltan campos obligatorios', async () => {
        mockRequest.body = { title: 'Solo título' };
        await createPublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    it('Creación: Debería rechazar (400) si la categoría no está permitida', async () => {
        mockRequest.body = {
            title: 'Cancha', description: '...', category: 'CATEGORIA_INVENTADA',
            imageUrl: 'url', region: 'RM', city: 'Santiago', availability: true, ownerId: 'dueño-1'
        };
        await createPublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    it('Creación: Debería bloquear (403) si la cuenta del dueño no es ACTIVE (ej. guest)', async () => {
        mockRequest.body = {
            title: 'Cancha', description: '...', category: 'DEPORTE',
            imageUrl: 'url', region: 'RM', city: 'Santiago', availability: true, ownerId: 'dueño-1'
        };

        // Simulamos que el perfil en GUEST
        prismaMock.profile.findUnique.mockResolvedValue({ id: 'dueño-1', accountStatus: 'guest' });

        await createPublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    //PUT /publications/:id
    it('Validación de Propiedad: Debería bloquear con 403 si un usuario intenta editar la cancha de otro (PUT)', async () => {
        mockRequest.params = { id: 'pub-1' };
        mockRequest.headers['x-user-id'] = 'usuario-intruso';
        mockRequest.body = { title: 'Título Hackeado' };

        prismaMock.publication.findUnique.mockResolvedValue({ id: 'pub-1', ownerId: 'dueño-1' });

        await updatePublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    //DELETE /publications/:id
    it('Eliminar: Debería bloquear con 403 si un usuario intenta borrar la cancha de otro (DELETE)', async () => {
        mockRequest.params = { id: 'pub-1' };
        mockRequest.headers['x-user-id'] = 'intruso';

        prismaMock.publication.findUnique.mockResolvedValue({ id: 'pub-1', ownerId: 'dueño-1' });

        await deletePublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    it('Eliminar: Debería borrar exitosamente (200) si el usuario es el dueño legítimo', async () => {
        mockRequest.params = { id: 'pub-1' };
        mockRequest.headers['x-user-id'] = 'dueño-1';

        prismaMock.publication.findUnique.mockResolvedValue({ id: 'pub-1', ownerId: 'dueño-1' });
        prismaMock.publication.delete.mockResolvedValue({ id: 'pub-1' });

        await deletePublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    //MÓDULO 4: EXCEPCIONES GLOBALES
    it('Excepciones: Debería retornar 500 si Prisma falla al obtener publicaciones', async () => {
        prismaMock.publication.findMany.mockRejectedValue(new Error('Caída de BD'));
        await getPublications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});