export interface AdminUser {
	id: string;
	name: string;
	privilege: number;
	email: string;
	createdAt: Date;
	lastSignIn: Date | null;
	disabled: boolean;
	emailVerified: boolean;
	updatedAt: Date;
}