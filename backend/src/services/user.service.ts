import prisma from "../repositories/prisma.repository.js";

interface UpdateProfileData {
    name?: string | null;
    phone?: string | null;
    avatarUrl?: string | null;
}

export const getAllProfiles = async () => {
    return await prisma.profile.findMany();
};

export const updateProfile = async (userId: string, data: UpdateProfileData) => {
    return await prisma.profile.update({
        where: { id: userId },
        data
    });
};