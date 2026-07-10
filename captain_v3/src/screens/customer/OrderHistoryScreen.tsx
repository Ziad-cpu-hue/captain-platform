import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { getOrderHistory } from '../../services/firebase';
import { useAuthStore } from '../../store';
import { VEHICLE_ICONS } from '../../utils/pricing';

const STATUS_COLORS: Record<string, { bg: string; text: string }> = {
  completed: { bg: Colors.primaryLight, text: Colors.primaryDark },
  cancelled: { bg: Colors.coralLight, text: Colors.coralDark },
  pending: { bg: Colors.amberLight, text: Colors.amberDark },
  accepted: { bg: Colors.amberLight, text: Colors.amberDark },
  on_route: { bg: Colors.amberLight, text: Colors.amberDark },
};

const DEMO_ORDERS = [
  { id: 'demo1', vehicleType: 'car', pickupAddress: 'Tahrir Square, Cairo', dropoffAddress: 'Cairo Airport, Terminal 2', distanceKm: 18.4, durationMin: 28, customerPays: 65.44, status: 'completed', createdAt: new Date() },
  { id: 'demo2', vehicleType: 'motorcycle', pickupAddress: 'Nasr City, Cairo', dropoffAddress: 'Heliopolis, Cairo', distanceKm: 8.2, durationMin: 16, customerPays: 22.10, status: 'completed', createdAt: new Date() },
  { id: 'demo3', vehicleType: 'truck', pickupAddress: 'Maadi, Cairo', dropoffAddress: 'New Cairo', distanceKm: 22.0, durationMin: 35, customerPays: 198.45, status: 'cancelled', createdAt: new Date() },
];

export default function OrderHistoryScreen() {
  const navigation = useNavigation<any>();
  const user = useAuthStore((s: any) => s.user);
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    getOrderHistory(user.uid, user.role === 'captain' ? 'captain' : 'customer')
      .then(data => setOrders(data.length > 0 ? data : DEMO_ORDERS))
      .catch(() => setOrders(DEMO_ORDERS))
      .finally(() => setLoading(false));
  }, [user]);

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.appbar}>
        <Text style={styles.appbarTitle}>Order History</Text>
      </View>
      <FlatList
        data={orders}
        keyExtractor={o => o.id}
        contentContainerStyle={{ padding: Spacing.md }}
        ListEmptyComponent={
          !loading ? (
            <View style={styles.empty}>
              <Text style={styles.emptyIcon}>📋</Text>
              <Text style={styles.emptyText}>No orders yet</Text>
              <Text style={styles.emptySub}>Your completed trips will appear here</Text>
            </View>
          ) : null
        }
        renderItem={({ item: o }) => {
          const sc = STATUS_COLORS[o.status] || { bg: Colors.lightBg, text: Colors.textMid };
          return (
            <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('OrderTracking', { orderId: o.id })} activeOpacity={0.7}>
              <View style={styles.cardHeader}>
                <View style={styles.vehicleChip}>
                  <Text style={{ fontSize: 20 }}>{VEHICLE_ICONS[o.vehicleType as keyof typeof VEHICLE_ICONS] || '🚗'}</Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.route} numberOfLines={1}>{o.pickupAddress}</Text>
                  <Text style={styles.routeTo} numberOfLines={1}>→ {o.dropoffAddress}</Text>
                </View>
                <View style={[styles.statusBadge, { backgroundColor: sc.bg }]}>
                  <Text style={[styles.statusText, { color: sc.text }]}>{o.status?.replace('_', ' ')}</Text>
                </View>
              </View>
              <View style={styles.cardFooter}>
                <Text style={styles.meta}>📏 {o.distanceKm} km · ⏱ {o.durationMin} min</Text>
                <Text style={styles.price}>{o.customerPays?.toFixed(2)} EGP</Text>
              </View>
            </TouchableOpacity>
          );
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  appbar: { paddingHorizontal: Spacing.md, paddingVertical: 16, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  appbarTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  empty: { alignItems: 'center', paddingTop: 80, gap: 8 },
  emptyIcon: { fontSize: 48 },
  emptyText: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  emptySub: { fontSize: FontSize.sm, color: Colors.textLight },
  card: { backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, padding: Spacing.md, marginBottom: 10 },
  cardHeader: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 10 },
  vehicleChip: { width: 44, height: 44, borderRadius: 10, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  route: { fontSize: FontSize.sm, fontWeight: '700', color: Colors.textDark },
  routeTo: { fontSize: 11, color: Colors.textMid, marginTop: 2 },
  statusBadge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: Radius.sm },
  statusText: { fontSize: FontSize.xs, fontWeight: '700', textTransform: 'capitalize' },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 0.5, borderColor: Colors.border, paddingTop: 10 },
  meta: { fontSize: FontSize.sm, color: Colors.textMid },
  price: { fontSize: FontSize.md, fontWeight: '700', color: Colors.primary },
});
