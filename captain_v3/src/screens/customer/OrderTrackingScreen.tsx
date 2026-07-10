import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation, useRoute } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { onOrderChanged, cancelOrder } from '../../services/firebase';

const STEPS = ['Requested', 'Accepted', 'On Route', 'Completed'];
const STATUS_STEP: Record<string, number> = { pending: 0, accepted: 1, on_route: 2, arrived: 2, completed: 3 };
const STATUS_LABELS: Record<string, string> = {
  pending: '🔍 Looking for a captain...',
  accepted: '✅ Captain is on the way!',
  on_route: '🚗 Trip in progress',
  arrived: '📍 Captain has arrived',
  completed: '🎉 Trip completed!',
  cancelled: '❌ Order cancelled',
};

export default function OrderTrackingScreen() {
  const navigation = useNavigation<any>();
  const route = useRoute<any>();
  const { orderId } = route.params;
  const [order, setOrder] = useState<any>(null);
  const [currentStep, setCurrentStep] = useState(0);

  useEffect(() => {
    const unsub = onOrderChanged(orderId, (o: any) => {
      setOrder(o);
      setCurrentStep(STATUS_STEP[o.status] ?? 0);
    });
    // Demo: simulate order progress if no Firebase
    if (!order) {
      setOrder({
        status: 'pending',
        pickupAddress: 'Pick-up location',
        dropoffAddress: 'Drop-off location',
        customerPays: 65.44,
        captainName: null,
      });
    }
    return unsub;
  }, [orderId]);

  async function handleCancel() {
    Alert.alert('Cancel Order', 'Are you sure you want to cancel?', [
      { text: 'No', style: 'cancel' },
      { text: 'Yes, Cancel', style: 'destructive', onPress: async () => { await cancelOrder(orderId); navigation.goBack(); } },
    ]);
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Order Tracking</Text>
      </View>

      <ScrollView contentContainerStyle={{ padding: Spacing.md }}>
        {/* Map placeholder */}
        <View style={styles.mapPlaceholder}>
          <Text style={styles.mapIcon}>🗺️</Text>
          <Text style={styles.mapText}>Live map with captain location</Text>
          <Text style={styles.mapSub}>Requires Google Maps API key</Text>
        </View>

        {/* Status card */}
        <View style={styles.statusCard}>
          <View style={styles.statusDot} />
          <View style={{ flex: 1 }}>
            <Text style={styles.statusText}>{STATUS_LABELS[order?.status] || '🔍 Looking for a captain...'}</Text>
            <Text style={styles.orderId}>Order #{orderId?.slice(0, 8).toUpperCase() || 'DEMO0001'}</Text>
          </View>
        </View>

        {/* Stepper */}
        <View style={styles.card}>
          <View style={styles.stepper}>
            {STEPS.map((label, i) => (
              <React.Fragment key={label}>
                <View style={styles.stepNode}>
                  <View style={[styles.stepCircle, i <= currentStep ? styles.stepDone : styles.stepTodo]}>
                    <Text style={{ color: i <= currentStep ? Colors.white : Colors.textLight, fontSize: 10, fontWeight: '700' }}>
                      {i <= currentStep ? '✓' : `${i + 1}`}
                    </Text>
                  </View>
                  <Text style={[styles.stepLabel, i <= currentStep && styles.stepLabelDone]}>{label}</Text>
                </View>
                {i < STEPS.length - 1 && (
                  <View style={[styles.stepLine, i < currentStep ? styles.stepLineDone : styles.stepLineTodo]} />
                )}
              </React.Fragment>
            ))}
          </View>
        </View>

        {/* Location info */}
        <View style={styles.card}>
          <View style={styles.locRow}>
            <View style={[styles.dot, { backgroundColor: Colors.primary }]} />
            <View style={{ flex: 1 }}>
              <Text style={styles.locLabel}>FROM</Text>
              <Text style={styles.locAddr}>{order?.pickupAddress || 'Pick-up location'}</Text>
            </View>
          </View>
          <View style={[styles.locRow, { marginTop: 10 }]}>
            <View style={[styles.dot, { backgroundColor: Colors.coral }]} />
            <View style={{ flex: 1 }}>
              <Text style={styles.locLabel}>TO</Text>
              <Text style={styles.locAddr}>{order?.dropoffAddress || 'Drop-off location'}</Text>
            </View>
          </View>
        </View>

        {/* Fare */}
        <View style={styles.fareCard}>
          <Text style={styles.fareLabel}>Total Fare</Text>
          <Text style={styles.fareValue}>{order?.customerPays?.toFixed(2) || '65.44'} EGP</Text>
        </View>

        {/* Chat button */}
        <TouchableOpacity style={styles.chatBtn} onPress={() => navigation.navigate('Chat', { threadId: `order_${orderId}`, title: order?.captainName || 'Captain' })}>
          <Text style={styles.chatBtnText}>💬  Chat with Captain</Text>
        </TouchableOpacity>

        {/* Cancel */}
        {(order?.status === 'pending' || !order?.status) && (
          <TouchableOpacity style={styles.cancelBtn} onPress={handleCancel}>
            <Text style={styles.cancelText}>Cancel Order</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: Spacing.md, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  backBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.lightBg, alignItems: 'center', justifyContent: 'center' },
  backArrow: { fontSize: 18, color: Colors.textDark },
  headerTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  mapPlaceholder: { height: 160, backgroundColor: '#e8f0e8', borderRadius: Radius.lg, alignItems: 'center', justifyContent: 'center', marginBottom: 12, borderWidth: 0.5, borderColor: Colors.border },
  mapIcon: { fontSize: 40, opacity: 0.4, marginBottom: 6 },
  mapText: { fontSize: FontSize.sm, color: Colors.textMid, fontWeight: '600' },
  mapSub: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 2 },
  statusCard: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 14, backgroundColor: Colors.primaryLight, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.primary + '40', marginBottom: 12 },
  statusDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: Colors.primary },
  statusText: { fontSize: FontSize.md, fontWeight: '700', color: Colors.primaryDark },
  orderId: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 2 },
  card: { backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, padding: Spacing.md, marginBottom: 12 },
  stepper: { flexDirection: 'row', alignItems: 'center' },
  stepNode: { alignItems: 'center', gap: 4 },
  stepCircle: { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  stepDone: { backgroundColor: Colors.primary },
  stepTodo: { backgroundColor: Colors.white, borderWidth: 1.5, borderColor: Colors.border },
  stepLabel: { fontSize: 8, color: Colors.textLight, textAlign: 'center', maxWidth: 50 },
  stepLabelDone: { color: Colors.primary, fontWeight: '700' },
  stepLine: { flex: 1, height: 2, marginBottom: 18 },
  stepLineDone: { backgroundColor: Colors.primary },
  stepLineTodo: { backgroundColor: Colors.border },
  locRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  dot: { width: 10, height: 10, borderRadius: 5, marginTop: 4 },
  locLabel: { fontSize: FontSize.xs, color: Colors.textLight, fontWeight: '700', marginBottom: 2 },
  locAddr: { fontSize: FontSize.sm, color: Colors.textDark },
  fareCard: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 14, backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, marginBottom: 12 },
  fareLabel: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  fareValue: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.primary },
  chatBtn: { borderWidth: 2, borderColor: Colors.primary, borderRadius: Radius.md, padding: 14, alignItems: 'center', marginBottom: 10 },
  chatBtnText: { color: Colors.primary, fontSize: FontSize.md, fontWeight: '700' },
  cancelBtn: { padding: 14, alignItems: 'center' },
  cancelText: { color: Colors.error, fontSize: FontSize.sm, fontWeight: '700' },
});
