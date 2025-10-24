import { AdminsService } from "./services";
import type { AdminPrivilegeLevel } from "./services/admins";

	// Helper function to get privilege name
export function getPrivilegeName(privilege: AdminPrivilegeLevel): string {
		return AdminsService.getPrivilegeName(privilege).replace('_', ' ');
	}