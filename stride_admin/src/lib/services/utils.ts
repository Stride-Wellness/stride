import type { Timestamp } from "firebase/firestore";

// Helper function to safely convert Firestore data to Date
export function toSafeDate(value: Timestamp | Date | { toDate(): Date } | null | undefined): Date {
	if (value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function') {
		return value.toDate();
	}
	if (value instanceof Date) {
		return value;
	}
	return new Date();
}