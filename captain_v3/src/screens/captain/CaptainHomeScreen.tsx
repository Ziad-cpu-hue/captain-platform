import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList, Switch, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { onPendingOrders, acceptOrder, setCaptainOnline } from '../../services/firebase';
import { useAuthStore, useCaptainStore } from '../../store';
import { VEHICLE_ICONS, VehicleType } from '../../utils/pricing';

const DEMO_ORDERS = [
  { id: 'demo_ord_1', vehicleType: 'car', pickupAddress: 'Nasr City, Cairo', dropoffAddress: 'Heliopolis, Cairo', distanceKm: 12.1, durationMin: 22, driverEarnings: 47.20, customerPays: 52.40 },
  { id: 'demo_ord_2', vehicleType: 'car', pickupAddress: 'Maadi, Cairo', dropoffAddress: 'New Cairo, 5th Settlement', distanceKm: 9.8, durationMin: 18, driverEarnings: 38.30, customerPays: 42.55 },
];

export default function CaptainHomeScreen() {
  const navigation = useNavigation<any>();
  const user = useAuthStore((s: any) => s.user);
  const { isOnline, pendingOrders, todayEarnings, totalTrips, setOnline, setPendingOrders } = useCaptainStore();
  const [vehicleFilter, setVehicleFilter] = useState<VehicleType>('car');

  useEffect(() => {
    const unsub = onPendingOrders(vehicleFilter, (orders) => {
      setPendingOrders(orders.length > 0 ? orders : DEMO_ORDERS);
    });
    // Show demo orders immediately
    setPendingOrders(DEMO_ORDERS);
    return unsub;
  }, [vehicleFilter]);

  async function handleToggleOnline(val: boolean) {
    setOnline(val);
    if (user?.uid) await setCaptainOnline(user.uid, val);
  }

  async function handleAccept(order: any) {
    try {
      await acceptOrder(order.id, user?.uid || 'demo', user?.displayName || 'Demo Captain');
      navigation.navigate('OrderTracking', { orderId: order.id });
    } catch (e: any) {
      Alert.alert('Error', e.message);
    }
  }

  const displayOrders = isOnline ? pendingOrders : [];

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* Dark header */}
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <View style={styles.logoRow}>
            <View style={styles.logoBox}><Text style={{ fontSize: 16 }}>🚗</Text></View>
            <View>
              <Text style={styles.appName}>CapTain</Text>
              <Text style={styles.mode}>Captain Mode</Text>
            </View>
          </View>
          <View style={styles.onlinePill}>
            <View style={[styles.onlineDot, { backgroundColor: isOnline ? '#4ADE80' : Colors.textLight }]} />
            <Text style={styles.onlineText}>{isOnline ? 'Online' : 'Offline'}</Text>
            <Switch
              value={isOnline}
              onValueChange={handleToggleOnline}
              trackColor={{ true: 'rgba(29,158,117,0.5)', false: 'rgba(255,255,255,0.15)' }}
              thumbColor={isOnline ? Colors.primary : Colors.textLight}
              style={{ transform: [{ scaleX: 0.85 }, { scaleY: 0.85 }] }}
            />
          </View>
        </View>

        {/* Earnings */}
        <View style={styles.earningsGrid}>
          <View style={styles.earnCard}>
            <Text style={styles.earnIcon}>💰</Text>
            <Text style={styles.earnValue}>{todayEarnings.toFixed(0)} EGP</Text>
            <Text style={styles.earnLabel}>Today's Earnings</Text>
          </View>
          <View style={styles.earnCard}>
            <Text style={styles.earnIcon}>🛣️</Text>
            <Text style={styles.earnValue}>{totalTrips}</Text>
            <Text style={styles.earnLabel}>Total Trips</Text>
          </View>
          <View style={styles.earnCard}>
            <Text style={styles.earnIcon}>⭐</Text>
            <Text style={styles.earnValue}>4.9</Text>
            <Text style={styles.earnLabel}>Rating</Text>
          </View>
        </View>
      </View>

      {/* Filter row */}
      <View style={styles.filterRow}>
        <Text style={styles.sectionTitle}>
          {isOnline ? `Available Requests (${displayOrders.length})` : 'Go online to receive requests'}
        </Text>
        <View style={styles.filterChips}>
          {(['car', 'motorcycle', 'truck'] as VehicleType[]).map(v => (
            <TouchableOpacity
              key={v}
              style={[styles.filterChip, vehicleFilter === v && styles.filterChipActive]}
              onPress={() => setVehicleFilter(v)}
            >
              <Text style={{ fontSize: 16 }}>{VEHICLE_ICONS[v]}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <FlatList
        data={displayOrders}
        keyExtractor={o => o.id}
        contentContainerStyle={{ padding: Spacing.md }}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>{isOnline ? '📭' : '💤'}</Text>
            <Text style={styles.emptyText}>{isOnline ? 'No requests yet' : 'You are offline'}</Text>
            <Text style={styles.emptySub}>{isOnline ? 'New orders will appear here' : 'Toggle the switch to go online'}</Text>
          </View>
        }
        renderItem={({ item: o }) => (
          <View style={styles.reqCard}>
            <View style={styles.reqHeader}>
              <View style={styles.reqVehicle}>
                <Text style={{ fontSize: 18 }}>{VEHICLE_ICONS[o.vehicleType as VehicleType] || '🚗'}</Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.reqFrom} numberOfLines={1}>{o.pickupAddress}</Text>
                <Text style={styles.reqTo} numberOfLines={1}>→ {o.dropoffAddress}</Text>
              </View>
              <View style={styles.earnBadge}>
                <Text style={styles.earnBadgeSub}>You earn</Text>
                <Text style={styles.earnBadgeVal}>{o.driverEarnings?.toFixed(2)} EGP</Text>
              </View>
            </View>
            <View style={styles.reqMeta}>
              <View style={styles.metaChip}><Text style={styles.metaText}>📏 {o.distanceKm} km</Text></View>
              <View style={styles.metaChip}><Text style={styles.metaText}>⏱ {o.durationMin} min</Text></View>
              <View style={styles.metaChip}><Text style={styles.metaText}>💳 {o.customerPays?.toFixed(2)} EGP total</Text></View>
            </View>
            <View style={styles.reqBtns}>
              <TouchableOpacity style={styles.rejectBtn} onPress={() => {}}>
                <Text style={styles.rejectText}>Reject</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.acceptBtn} onPress={() => handleAccept(o)}>
                <Text style={styles.acceptText}>Accept Trip ✓</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  header: { backgroundColor: Colors.dark, padding: Spacing.md, paddingBottom: 18 },
  headerTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  logoRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  logoBox: { width: 36, height: 36, borderRadius: 10, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center' },
  appName: { fontSize: FontSize.md, fontWeight: '700', color: Colors.white },
  mode: { fontSize: FontSize.xs, color: Colors.textLight },
  onlinePill: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 10, paddingVertical: 6, borderRadius: 20, backgroundColor: 'rgba(255,255,255,0.1)' },
  onlineDot: { width: 7, height: 7, borderRadius: 4 },
  onlineText: { color: Colors.white, fontSize: FontSize.sm, fontWeight: '600' },
  earningsGrid: { flexDirection: 'row', gap: 8 },
  earnCard: { flex: 1, padding: 12, backgroundColor: 'rgba(255,255,255,0.07)', borderRadius: Radius.md, borderWidth: 0.5, borderColor: 'rgba(255,255,255,0.1)' },
  earnIcon: { fontSize: 16, marginBottom: 4 },
  earnValue: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.white },
  earnLabel: { fontSize: 9, color: Colors.textLight, marginTop: 2 },
  filterRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: Spacing.md, paddingVertical: 12 },
  sectionTitle: { fontSize: FontSize.sm, fontWeight: '700', color: Colors.textDark, flex: 1 },
  filterChips: { flexDirection: 'row', gap: 6 },
  filterChip: { width: 36, height: 36, borderRadius: Radius.md, backgroundColor: Colors.lightBg, borderWidth: 0.5, borderColor: Colors.border, alignItems: 'center', justifyContent: 'center' },
  filterChipActive: { backgroundColor: Colors.primaryLight, borderColor: Colors.primary },
  empty: { alignItems: 'center', paddingTop: 60, gap: 8 },
  emptyIcon: { fontSize: 48 },
  emptyText: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  emptySub: { fontSize: FontSize.sm, color: Colors.textLight, textAlign: 'center' },
  reqCard: { backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, padding: Spacing.md, marginBottom: 12 },
  reqHeader: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 10 },
  reqVehicle: { width: 40, height: 40, borderRadius: 10, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  reqFrom: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  reqTo: { fontSize: FontSize.sm, color: Colors.textMid, marginTop: 2 },
  earnBadge: { alignItems: 'flex-end' },
  earnBadgeSub: { fontSize: FontSize.xs, color: Colors.textLight },
  earnBadgeVal: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.primary },
  reqMeta: { flexDirection: 'row', gap: 6, marginBottom: 12, flexWrap: 'wrap' },
  metaChip: { paddingHorizontal: 8, paddingVertical: 4, backgroundColor: Colors.lightBg, borderRadius: Radius.sm, borderWidth: 0.5, borderColor: Colors.border },
  metaText: { fontSize: 10, fontWeight: '600', color: Colors.textDark },
  reqBtns: { flexDirection: 'row', gap: 8 },
  rejectBtn: { flex: 1, padding: 11, borderRadius: Radius.md, borderWidth: 1.5, borderColor: Colors.error, alignItems: 'center' },
  rejectText: { color: Colors.error, fontSize: FontSize.sm, fontWeight: '700' },
  acceptBtn: { flex: 2, padding: 11, borderRadius: Radius.md, backgroundColor: Colors.primary, alignItems: 'center' },
  acceptText: { color: Colors.white, fontSize: FontSize.sm, fontWeight: '700' },
});
