import { describe, it, expect, vi, beforeEach } from 'vitest';
import { updateMyProfile } from '../src/controllers/user.controller';

const prismaMock = vi.hoisted(() => ({
    profile: {
        findMany: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
    }
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: class { constructor() { return prismaMock; } },
    AccountStatus: { guest: 'guest', active: 'active' }
}));

vi.mock('../src/services/user.service', () => ({
    getAllProfiles: vi.fn()
}));

describe('Módulo 1b: Perfiles - PUT /users/me', () => {
    let mockRequest: any;
    let mockReply: any;

    beforeEach(() => {
        vi.clearAllMocks();
        mockRequest = { body: {}, headers: {} };
        mockReply = {
            status: vi.fn().mockReturnThis(),
            send: vi.fn()
        };
    });

    it('Debería fallar con 401 si no se envía x-user-id', async () => {
        mockRequest.body = { phone: '+56911111111' };

        await updateMyProfile(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(401);
        expect(prismaMock.profile.update).not.toHaveBeenCalled();
    });

    it('Debería fallar con 404 si el perfil no existe', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-fantasma';
        mockRequest.body = { name: 'Nuevo Nombre' };
        prismaMock.profile.findUnique.mockResolvedValue(null);

        await updateMyProfile(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(404);
        expect(prismaMock.profile.update).not.toHaveBeenCalled();
    });

    it('Éxito parcial: actualiza solo phone y responde 200 con el perfil actualizado', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.body = { phone: '+56922222222' };
        prismaMock.profile.findUnique.mockResolvedValue({
            id: 'uuid-supabase',
            name: 'Nombre Original',
            phone: '+56900000000',
            accountStatus: 'active'
        });
        prismaMock.profile.update.mockResolvedValue({
            id: 'uuid-supabase',
            name: 'Nombre Original',
            phone: '+56922222222',
            accountStatus: 'active'
        });

        await updateMyProfile(mockRequest, mockReply);

        expect(prismaMock.profile.update).toHaveBeenCalledWith({
            where: { id: 'uuid-supabase' },
            data: { phone: '+56922222222' }
        });
        expect(mockReply.status).toHaveBeenCalledWith(200);
        expect(mockReply.send).toHaveBeenCalledWith({
            data: expect.objectContaining({ phone: '+56922222222' })
        });
    });

    it('name ausente en el body no se pisa (solo se actualizan los campos presentes)', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.body = { avatarUrl: 'https://cdn.test/avatar.png' };
        prismaMock.profile.findUnique.mockResolvedValue({
            id: 'uuid-supabase',
            name: 'Nombre Que No Debe Cambiar',
            phone: null,
            accountStatus: 'guest'
        });
        prismaMock.profile.update.mockResolvedValue({
            id: 'uuid-supabase',
            name: 'Nombre Que No Debe Cambiar',
            phone: null,
            avatarUrl: 'https://cdn.test/avatar.png',
            accountStatus: 'guest'
        });

        await updateMyProfile(mockRequest, mockReply);

        const dataArg = prismaMock.profile.update.mock.calls[0][0].data;
        expect(dataArg).not.toHaveProperty('name');
        expect(dataArg).toEqual({ avatarUrl: 'https://cdn.test/avatar.png' });
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Debería retornar 500 si Prisma falla al actualizar', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.body = { name: 'Nuevo Nombre' };
        prismaMock.profile.findUnique.mockResolvedValue({ id: 'uuid-supabase' });
        prismaMock.profile.update.mockRejectedValue(new Error('Prisma Network Error'));

        await updateMyProfile(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});
