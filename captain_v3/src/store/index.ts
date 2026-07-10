import { create } from 'zustand';
import { DEFAULT_SETTINGS, AppSettings, VehicleType } from '../utils/pricing';

interface AuthState {
  user: any;
  isLoading: boolean;
  setUser: (u: any) => void;
  setLoading: (v: boolean) => void;
}
export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  setUser: (user) => set({ user }),
  setLoading: (isLoading) => set({ isLoading }),
}));

interface SettingsState {
  settings: AppSettings;
  setSettings: (s: AppSettings) => void;
}
export const useSettingsStore = create<SettingsState>((set) => ({
  settings: DEFAULT_SETTINGS,
  setSettings: (settings) => set({ settings }),
}));

interface GeoPoint { latitude: number; longitude: number; }

interface OrderDraft {
  vehicleType: VehicleType | null;
  pickupLocation: GeoPoint | null;
  dropoffLocation: GeoPoint | null;
  pickupAddress: string;
  dropoffAddress: string;
  distanceKm: number;
  durationMin: number;
}
const emptyDraft: OrderDraft = { vehicleType: null, pickupLocation: null, dropoffLocation: null, pickupAddress: '', dropoffAddress: '', distanceKm: 0, durationMin: 0 };

interface OrderDraftState {
  draft: OrderDraft;
  setVehicleType: (v: VehicleType) => void;
  setPickup: (loc: GeoPoint, addr: string) => void;
  setDropoff: (loc: GeoPoint, addr: string) => void;
  setRoute: (km: number, min: number) => void;
  resetDraft: () => void;
}
export const useOrderDraftStore = create<OrderDraftState>((set) => ({
  draft: emptyDraft,
  setVehicleType: (vehicleType) => set((s) => ({ draft: { ...s.draft, vehicleType } })),
  setPickup: (loc, addr) => set((s) => ({ draft: { ...s.draft, pickupLocation: loc, pickupAddress: addr } })),
  setDropoff: (loc, addr) => set((s) => ({ draft: { ...s.draft, dropoffLocation: loc, dropoffAddress: addr } })),
  setRoute: (distanceKm, durationMin) => set((s) => ({ draft: { ...s.draft, distanceKm, durationMin } })),
  resetDraft: () => set({ draft: emptyDraft }),
}));

interface ActiveOrderState {
  activeOrder: any;
  captainLocation: GeoPoint | null;
  setActiveOrder: (o: any) => void;
  setCaptainLocation: (l: GeoPoint | null) => void;
}
export const useActiveOrderStore = create<ActiveOrderState>((set) => ({
  activeOrder: null,
  captainLocation: null,
  setActiveOrder: (activeOrder) => set({ activeOrder }),
  setCaptainLocation: (captainLocation) => set({ captainLocation }),
}));

interface CaptainState {
  isOnline: boolean;
  pendingOrders: any[];
  todayEarnings: number;
  totalTrips: number;
  setOnline: (v: boolean) => void;
  setPendingOrders: (o: any[]) => void;
  setEarnings: (n: number) => void;
  setTotalTrips: (n: number) => void;
}
export const useCaptainStore = create<CaptainState>((set) => ({
  isOnline: false,
  pendingOrders: [],
  todayEarnings: 0,
  totalTrips: 0,
  setOnline: (isOnline) => set({ isOnline }),
  setPendingOrders: (pendingOrders) => set({ pendingOrders }),
  setEarnings: (todayEarnings) => set({ todayEarnings }),
  setTotalTrips: (totalTrips) => set({ totalTrips }),
}));
