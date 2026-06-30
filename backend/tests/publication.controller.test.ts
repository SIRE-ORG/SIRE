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
        update: vi.fn(),
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
        expect(mockReply.status).toHaveBeenCalledWith(401);
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

    it('Creación: Debería bloquear (403) si la cuenta del dueño no es ACTIVE', async () => {
        mockRequest.body = {
            title: 'Cancha', description: '...', category: 'DEPORTE',
            imageUrl: 'url', region: 'RM', city: 'Santiago', availability: true, ownerId: 'dueño-1'
        };

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

    //Nuevos tests

    // Verifica que se pueda leer correctamente una publicación individual si el ID existe.
    it('Detalle: Debería retornar una publicación por ID (200)', async () => {
        mockRequest.params = { id: 'pub-1' };
        prismaMock.publication.findUnique.mockResolvedValue({ id: 'pub-1', title: 'Cancha Central' });

        await getPublicationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    // Asegura que el backend maneje amigablemente la búsqueda de un ID que no existe (ej. un link viejo).
    it('Detalle: Debería retornar 404 si la publicación no existe', async () => {
        mockRequest.params = { id: 'pub-invalida' };
        prismaMock.publication.findUnique.mockResolvedValue(null);

        await getPublicationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    // Valida el "Happy Path" del panel de control del dueño: ver sus propias canchas.
    it('Mis Publicaciones: Debería retornar la lista del dueño (200)', async () => {
        mockRequest.headers['x-user-id'] = 'dueño-1';
        prismaMock.publication.findMany.mockResolvedValue([{ id: 'pub-1', title: 'Mi Cancha' }]);

        await getMyPublications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    // Comprueba que el dueño legítimo efectivamente puede cambiar los datos de su publicación.
    it('Edición: Debería actualizar la publicación (200) si es el dueño legítimo', async () => {
        mockRequest.params = { id: 'pub-1' };
        mockRequest.headers['x-user-id'] = 'dueño-1';
        mockRequest.body = { title: 'Cancha Remodelada' };

        prismaMock.publication.findUnique.mockResolvedValue({ id: 'pub-1', ownerId: 'dueño-1' });
        prismaMock.publication.update.mockResolvedValue({ id: 'pub-1', title: 'Cancha Remodelada' });

        await updatePublication(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    //MÓDULO 4: EXCEPCIONES GLOBALES
    it('Excepciones: Debería retornar 500 si Prisma falla al obtener publicaciones', async () => {
        prismaMock.publication.findMany.mockRejectedValue(new Error('Caída de BD'));
        await getPublications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});