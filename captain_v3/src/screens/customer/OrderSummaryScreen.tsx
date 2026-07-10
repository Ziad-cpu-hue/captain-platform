import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { useOrderDraftStore, useAuthStore, useSettingsStore } from '../../store';
import { createOrder } from '../../services/firebase';
import { calculatePrice, VEHICLE_LABELS, VEHICLE_ICONS } from '../../utils/pricing';

export default function OrderSummaryScreen() {
  const navigation = useNavigation<any>();
  const { draft, resetDraft } = useOrderDraftStore();
  const user = useAuthStore((s: any) => s.user);
  const settings = useSettingsStore((s: any) => s.settings);
  const [loading, setLoading] = useState(false);

  const pricing = draft.vehicleType ? calculatePrice(
    draft.distanceKm || 5.2,
    draft.vehicleType,
    settings,
    draft.durationMin || 13
  ) : null;

  async function handleConfirm() {
    if (!pricing || !draft.vehicleType || !user) return;
    try {
      setLoading(true);
      const orderId = await createOrder({
        customerId: user.uid,
        customerName: user.displayName,
        vehicleType: draft.vehicleType,
        pickupLocation: draft.pickupLocation || { latitude: 30.0444, longitude: 31.2357 },
        dropoffLocation: draft.dropoffLocation || { latitude: 30.0600, longitude: 31.2500 },
        pickupAddress: draft.pickupAddress || 'Pick-up location',
        dropoffAddress: draft.dropoffAddress || 'Drop-off location',
        distanceKm: pricing.distanceKm,
        durationMin: pricing.durationMin,
        fuelCost: pricing.fuelCost,
        driverEarnings: pricing.driverEarnings,
        platformFee: pricing.platformFee,
        customerPays: pricing.customerPays,
      });
      resetDraft();
      navigation.replace('OrderTracking', { orderId });
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setLoading(false);
    }
  }

  if (!pricing || !draft.vehicleType) return null;

  const consumptionMap: Record<string, number> = { car: 8, motorcycle: 3.5, truck: 18 };

  const rows = [
    { label: 'Distance', sub: `${consumptionMap[draft.vehicleType]}L/100km consumption`, value: `${pricing.distanceKm} km` },
    { label: 'Fuel cost', sub: `${pricing.litersUsed}L × ${settings.fuelPricePerLiter} EGP/L`, value: `${pricing.fuelCost.toFixed(2)} EGP` },
    { label: 'Driver earnings', sub: `Fuel + ${settings.driverProfitPercent}% profit`, value: `${pricing.driverEarnings.toFixed(2)} EGP` },
    { label: 'Platform fee', sub: `${settings.platformFeePercent}% of transaction`, value: `${pricing.platformFee.toFixed(2)} EGP`, dim: true },
  ];

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.appbar}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.appbarTitle}>Order Summary</Text>
      </View>

      <ScrollView contentContainerStyle={{ padding: Spacing.md }}>
        {/* Trip card */}
        <View style={styles.card}>
          <View style={styles.tripHeader}>
            <View style={styles.vehicleIcon}>
              <Text style={{ fontSize: 22 }}>{VEHICLE_ICONS[draft.vehicleType]}</Text>
            </View>
            <View>
              <Text style={styles.vehicleTitle}>{VEHICLE_LABELS[draft.vehicleType]}</Text>
              <Text style={styles.vehicleSub}>{pricing.distanceKm} km · {pricing.durationMin} min</Text>
            </View>
          </View>
          <View style={styles.divider} />
          <View style={styles.locRow}>
            <View style={[styles.dot, { backgroundColor: Colors.primary }]} />
            <View style={{ flex: 1 }}>
              <Text style={styles.locLabel}>FROM</Text>
              <Text style={styles.locAddr} numberOfLines={2}>{draft.pickupAddress || 'Pick-up location'}</Text>
            </View>
          </View>
          <View style={[styles.locRow, { marginTop: 8 }]}>
            <View style={[styles.dot, { backgroundColor: Colors.coral }]} />
            <View style={{ flex: 1 }}>
              <Text style={styles.locLabel}>TO</Text>
              <Text style={styles.locAddr} numberOfLines={2}>{draft.dropoffAddress || 'Drop-off location'}</Text>
            </View>
          </View>
        </View>

        {/* Fare breakdown */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Price Breakdown</Text>
          {rows.map(r => (
            <View key={r.label} style={styles.fareRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.fareLabel}>{r.label}</Text>
                <Text style={styles.fareSub}>{r.sub}</Text>
              </View>
              <Text style={[styles.fareValue, r.dim && { color: Colors.textMid }]}>{r.value}</Text>
            </View>
          ))}
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Total Fare</Text>
            <Text style={styles.totalValue}>{pricing.customerPays.toFixed(2)} EGP</Text>
          </View>
        </View>

        {/* Info note */}
        <View style={styles.infoNote}>
          <Text style={styles.infoText}>ℹ  Fuel price: {settings.fuelPricePerLiter} EGP/L (92 Octane). Final fare calculated on exact GPS distance.</Text>
        </View>

        <TouchableOpacity style={styles.confirmBtn} onPress={handleConfirm} disabled={loading}>
          {loading
            ? <ActivityIndicator color={Colors.white} />
            : <Text style={styles.confirmText}>Confirm Booking · {pricing.customerPays.toFixed(2)} EGP</Text>
          }
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  appbar: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: Spacing.md, paddingVertical: 14, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  backBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.lightBg, alignItems: 'center', justifyContent: 'center' },
  backArrow: { fontSize: 18, color: Colors.textDark },
  appbarTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  card: { backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, padding: Spacing.md, marginBottom: 12 },
  tripHeader: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 14 },
  vehicleIcon: { width: 48, height: 48, borderRadius: 12, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  vehicleTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  vehicleSub: { fontSize: 11, color: Colors.textMid, marginTop: 2 },
  divider: { height: 0.5, backgroundColor: Colors.border, marginBottom: 12 },
  locRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  dot: { width: 10, height: 10, borderRadius: 5, marginTop: 4 },
  locLabel: { fontSize: FontSize.xs, color: Colors.textLight, fontWeight: '700', marginBottom: 2 },
  locAddr: { fontSize: FontSize.sm, color: Colors.textDark, lineHeight: 18 },
  cardTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark, marginBottom: 14 },
  fareRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 },
  fareLabel: { fontSize: FontSize.sm, fontWeight: '600', color: Colors.textDark },
  fareSub: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 2 },
  fareValue: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', borderTopWidth: 0.5, borderColor: Colors.border, paddingTop: 14, marginTop: 4 },
  totalLabel: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  totalValue: { fontSize: FontSize.xxl, fontWeight: '700', color: Colors.primary },
  infoNote: { backgroundColor: Colors.primaryLight, borderRadius: Radius.md, padding: 12, marginBottom: 14 },
  infoText: { fontSize: 11, color: Colors.primaryDark, lineHeight: 17 },
  confirmBtn: { backgroundColor: Colors.primary, borderRadius: Radius.md, padding: 16, alignItems: 'center' },
  confirmText: { color: Colors.white, fontSize: FontSize.md, fontWeight: '700' },
});
