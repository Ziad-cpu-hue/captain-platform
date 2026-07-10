export type VehicleType = 'car' | 'motorcycle' | 'truck';

export interface AppSettings {
  fuelPricePerLiter: number;
  driverProfitPercent: number;
  platformFeePercent: number;
}

export const DEFAULT_SETTINGS: AppSettings = {
  fuelPricePerLiter: 22.25,
  driverProfitPercent: 80,
  platformFeePercent: 10,
};

const CONSUMPTION: Record<VehicleType, number> = {
  car: 8.0,
  motorcycle: 3.5,
  truck: 18.0,
};

export const VEHICLE_LABELS: Record<VehicleType, string> = {
  car: 'Private Car',
  motorcycle: 'Motorcycle',
  truck: 'Refrigerated Truck',
};

export const VEHICLE_ICONS: Record<VehicleType, string> = {
  car: '🚗',
  motorcycle: '🏍️',
  truck: '🚚',
};

export interface PricingResult {
  distanceKm: number;
  litersUsed: number;
  fuelCost: number;
  driverProfit: number;
  driverEarnings: number;
  platformFee: number;
  customerPays: number;
  durationMin: number;
}

export function calculatePrice(
  distanceKm: number,
  vehicle: VehicleType,
  settings: AppSettings,
  durationMin = 0,
): PricingResult {
  const r = (n: number) => Math.round(n * 100) / 100;
  const litersUsed = (distanceKm * CONSUMPTION[vehicle]) / 100;
  const fuelCost = litersUsed * settings.fuelPricePerLiter;
  const driverProfit = fuelCost * (settings.driverProfitPercent / 100);
  const driverEarnings = fuelCost + driverProfit;
  const platformFee = driverEarnings * (settings.platformFeePercent / 100);
  const customerPays = driverEarnings + platformFee;
  return { distanceKm: r(distanceKm), litersUsed: r(litersUsed), fuelCost: r(fuelCost), driverProfit: r(driverProfit), driverEarnings: r(driverEarnings), platformFee: r(platformFee), customerPays: r(customerPays), durationMin };
}
