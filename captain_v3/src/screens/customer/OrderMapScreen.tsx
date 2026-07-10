import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation, useRoute } from '@react-navigation/native';
import * as Location from 'expo-location';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { useOrderDraftStore } from '../../store';
import { VEHICLE_LABELS, VEHICLE_ICONS, VehicleType } from '../../utils/pricing';

interface GeoPoint { latitude: number; longitude: number; }

async function reverseGeocode(loc: GeoPoint): Promise<string> {
  try {
    const res = await Location.reverseGeocodeAsync(loc);
    if (res.length > 0) {
      const a = res[0];
      return [a.street, a.district, a.city].filter(Boolean).join(', ') || `${loc.latitude.toFixed(4)}, ${loc.longitude.toFixed(4)}`;
    }
  } catch {}
  return `${loc.latitude.toFixed(4)}, ${loc.longitude.toFixed(4)}`;
}

function calcDistance(a: GeoPoint, b: GeoPoint): number {
  const R = 6371;
  const dLat = (b.latitude - a.latitude) * Math.PI / 180;
  const dLon = (b.longitude - a.longitude) * Math.PI / 180;
  const x = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(a.latitude * Math.PI/180) * Math.cos(b.latitude * Math.PI/180) * Math.sin(dLon/2) * Math.sin(dLon/2);
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1-x));
}

export default function OrderMapScreen() {
  const navigation = useNavigation<any>();
  const route = useRoute<any>();
  const vehicleType = route.params?.vehicleType as VehicleType;
  const { setVehicleType, setPickup, setDropoff, setRoute } = useOrderDraftStore();
  const [pickup, setPickupLocal] = useState<GeoPoint | null>(null);
  const [dropoff, setDropoffLocal] = useState<GeoPoint | null>(null);
  const [step, setStep] = useState<'pickup' | 'dropoff'>('pickup');
  const [loading, setLoading] = useState(false);
  const [pickupAddr, setPickupAddr] = useState('');
  const [dropoffAddr, setDropoffAddr] = useState('');

  useEffect(() => {
    setVehicleType(vehicleType);
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status === 'granted') {
        const loc = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
        const gp: GeoPoint = { latitude: loc.coords.latitude, longitude: loc.coords.longitude };
        setPickupLocal(gp);
        setStep('dropoff');
        const addr = await reverseGeocode(gp);
        setPickupAddr(addr);
        setPickup(gp, addr);
      }
    })();
  }, []);

  async function handleSetLocation(isPickup: boolean) {
    setLoading(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') { Alert.alert('Location permission required'); return; }
      const loc = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
      // Simulate a random offset for drop-off demo
      const offset = isPickup ? 0 : (Math.random() * 0.04 - 0.02);
      const gp: GeoPoint = { latitude: loc.coords.latitude + offset, longitude: loc.coords.longitude + offset };
      const addr = await reverseGeocode(gp);
      if (isPickup) { setPickupLocal(gp); setPickupAddr(addr); setPickup(gp, addr); setStep('dropoff'); }
      else {
        setDropoffLocal(gp); setDropoffAddr(addr); setDropoff(gp, addr);
        if (pickup) {
          const km = Math.round(calcDistance(pickup, gp) * 10) / 10;
          const min = Math.ceil(km * 2.5);
          setRoute(km || 5.2, min || 13);
        }
      }
    } catch (e: any) { Alert.alert('Error', e.message); }
    finally { setLoading(false); }
  }

  const distanceKm = pickup && dropoff ? Math.round(calcDistance(pickup, dropoff) * 10) / 10 : 0;
  const durationMin = Math.ceil(distanceKm * 2.5);

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>{VEHICLE_ICONS[vehicleType]} {VEHICLE_LABELS[vehicleType]}</Text>
      </View>

      {/* Map placeholder */}
      <View style={styles.mapArea}>
        <View style={styles.mapGrid} />
        <Text style={styles.mapIcon}>🗺️</Text>
        <Text style={styles.mapHint}>
          {step === 'pickup' ? 'Set your pick-up location first' : pickup ? 'Now set your drop-off location' : 'Set locations below'}
        </Text>
        {pickup && (
          <View style={styles.mapPin}>
            <Text style={{ fontSize: 28 }}>📍</Text>
            <Text style={styles.mapPinLabel}>Pick-up</Text>
          </View>
        )}
        {dropoff && (
          <View style={[styles.mapPin, { bottom: 60, right: 60 }]}>
            <Text style={{ fontSize: 28 }}>🏁</Text>
            <Text style={[styles.mapPinLabel, { color: Colors.coral }]}>Drop-off</Text>
          </View>
        )}
      </View>

      {/* Bottom Sheet */}
      <View style={styles.sheet}>
        <View style={styles.handle} />

        {/* Pick-up location */}
        <TouchableOpacity style={[styles.locCard, step === 'pickup' && styles.locCardActive]} onPress={() => handleSetLocation(true)}>
          <View style={[styles.dot, { backgroundColor: Colors.primary }]} />
          <View style={{ flex: 1 }}>
            <Text style={styles.locLabel}>PICK-UP LOCATION</Text>
            <Text style={styles.locAddr} numberOfLines={1}>{pickupAddr || 'Tap to use current location'}</Text>
          </View>
          {loading && step === 'pickup' ? <ActivityIndicator size="small" color={Colors.primary} /> : <Text style={styles.locIcon}>📍</Text>}
        </TouchableOpacity>

        {/* Drop-off location */}
        <TouchableOpacity style={[styles.locCard, step === 'dropoff' && styles.locCardActive]} onPress={() => handleSetLocation(false)} disabled={!pickup}>
          <View style={[styles.dot, { backgroundColor: Colors.coral }]} />
          <View style={{ flex: 1 }}>
            <Text style={styles.locLabel}>DROP-OFF LOCATION</Text>
            <Text style={styles.locAddr} numberOfLines={1}>{dropoffAddr || (pickup ? 'Tap to set drop-off' : 'Set pick-up first')}</Text>
          </View>
          {loading && step === 'dropoff' ? <ActivityIndicator size="small" color={Colors.coral} /> : <Text style={styles.locIcon}>🏁</Text>}
        </TouchableOpacity>

        {/* Route info */}
        {distanceKm > 0 && (
          <View style={styles.routeChips}>
            <View style={styles.chip}><Text style={styles.chipText}>📏  {distanceKm} km</Text></View>
            <View style={styles.chipDivider} />
            <View style={styles.chip}><Text style={styles.chipText}>⏱  ~{durationMin} min</Text></View>
          </View>
        )}

        <TouchableOpacity
          style={[styles.btn, (!pickup || !dropoff) && styles.btnDisabled]}
          onPress={() => navigation.navigate('OrderSummary')}
          disabled={!pickup || !dropoff}
        >
          <Text style={styles.btnText}>Continue to Price Estimate</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: Spacing.md, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  backBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.lightBg, alignItems: 'center', justifyContent: 'center' },
  backArrow: { fontSize: 18, color: Colors.textDark },
  headerTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  mapArea: { flex: 1, backgroundColor: '#e8f0e8', alignItems: 'center', justifyContent: 'center', position: 'relative' },
  mapGrid: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, borderWidth: 0 },
  mapIcon: { fontSize: 60, opacity: 0.3 },
  mapHint: { fontSize: FontSize.sm, color: Colors.textMid, textAlign: 'center', marginTop: 8, paddingHorizontal: 20 },
  mapPin: { position: 'absolute', bottom: 80, left: 60, alignItems: 'center' },
  mapPinLabel: { fontSize: FontSize.xs, fontWeight: '700', color: Colors.primary, marginTop: 2 },
  sheet: { backgroundColor: Colors.white, borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: Spacing.md, paddingBottom: 30, elevation: 8 },
  handle: { width: 40, height: 3, backgroundColor: Colors.border, borderRadius: 2, alignSelf: 'center', marginBottom: 16 },
  locCard: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 14, borderRadius: Radius.lg, borderWidth: 1.5, borderColor: Colors.border, marginBottom: 10, backgroundColor: Colors.white },
  locCardActive: { borderColor: Colors.primary, backgroundColor: Colors.primaryLight + '40' },
  dot: { width: 12, height: 12, borderRadius: 6 },
  locLabel: { fontSize: FontSize.xs, fontWeight: '700', color: Colors.textLight, marginBottom: 2 },
  locAddr: { fontSize: FontSize.sm, color: Colors.textDark },
  locIcon: { fontSize: 18 },
  routeChips: { flexDirection: 'row', alignItems: 'center', padding: 12, backgroundColor: Colors.lightBg, borderRadius: Radius.md, borderWidth: 0.5, borderColor: Colors.border, marginBottom: 12 },
  chip: { flex: 1, alignItems: 'center' },
  chipText: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  chipDivider: { width: 0.5, height: 24, backgroundColor: Colors.border },
  btn: { backgroundColor: Colors.primary, borderRadius: Radius.md, padding: 15, alignItems: 'center' },
  btnDisabled: { backgroundColor: Colors.border },
  btnText: { color: Colors.white, fontSize: FontSize.md, fontWeight: '700' },
});
