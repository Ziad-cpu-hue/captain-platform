import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { useAuthStore } from '../../store';

const SERVICES = [
  { type: 'car', icon: '🚗', title: 'Private Car', subtitle: 'Comfortable rides for daily travel', fuel: '8L/100km average', badge: 'Most Popular', badgeBg: Colors.primaryLight, badgeText: Colors.primaryDark },
  { type: 'motorcycle', icon: '🏍️', title: 'Motorcycle', subtitle: 'Fast delivery for small packages', fuel: '3.5L/100km average', badge: 'Fastest', badgeBg: Colors.amberLight, badgeText: Colors.amberDark },
  { type: 'truck', icon: '🚚', title: 'Refrigerated Truck', subtitle: 'Cold chain transport for goods', fuel: '18L/100km average', badge: 'Cargo', badgeBg: Colors.coralLight, badgeText: Colors.coralDark },
];

export default function HomeScreen() {
  const navigation = useNavigation<any>();
  const user = useAuthStore((s: any) => s.user);
  const firstName = user?.displayName?.split(' ')[0] ?? 'there';

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <StatusBar barStyle="dark-content" backgroundColor={Colors.white} />

      {/* AppBar */}
      <View style={styles.appbar}>
        <View style={styles.logoBox}><Text style={{ fontSize: 16 }}>🚗</Text></View>
        <Text style={styles.appbarTitle}>CapTain</Text>
        <View style={{ flex: 1 }} />
        <Text style={{ fontSize: 22, marginRight: 12 }}>🔔</Text>
        <View style={styles.avatar}><Text style={{ fontSize: 16 }}>👤</Text></View>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={{ flex: 1 }}>
        {/* Greeting */}
        <View style={styles.greeting}>
          <Text style={styles.greetName}>Hello, {firstName} 👋</Text>
          <Text style={styles.greetSub}>What would you like to request today?</Text>
        </View>

        <View style={styles.sectionDivider} />
        <Text style={styles.sectionLabel}>OUR SERVICES</Text>

        {/* Service Cards */}
        {SERVICES.map(s => (
          <TouchableOpacity
            key={s.type}
            style={styles.card}
            onPress={() => navigation.navigate('OrderMap', { vehicleType: s.type })}
            activeOpacity={0.7}
          >
            <View style={styles.cardIcon}><Text style={{ fontSize: 24 }}>{s.icon}</Text></View>
            <View style={{ flex: 1 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <Text style={styles.cardTitle}>{s.title}</Text>
                <View style={[styles.badge, { backgroundColor: s.badgeBg }]}>
                  <Text style={[styles.badgeText, { color: s.badgeText }]}>{s.badge}</Text>
                </View>
              </View>
              <Text style={styles.cardSub}>{s.subtitle}</Text>
              <Text style={styles.cardFuel}>⛽ {s.fuel}</Text>
            </View>
            <Text style={styles.chevron}>›</Text>
          </TouchableOpacity>
        ))}

        {/* Captain Banner */}
        <TouchableOpacity style={styles.captainBanner} onPress={() => navigation.navigate('CaptainApply')} activeOpacity={0.8}>
          <View style={styles.bannerIcon}><Text style={{ fontSize: 22 }}>⭐</Text></View>
          <View style={{ flex: 1 }}>
            <Text style={styles.bannerTitle}>Become a Captain</Text>
            <Text style={styles.bannerSub}>Join our team and start earning</Text>
          </View>
          <Text style={{ color: Colors.primary, fontSize: 18 }}>›</Text>
        </TouchableOpacity>

        <View style={{ height: 30 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  appbar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: Spacing.md, paddingVertical: 12, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  logoBox: { width: 36, height: 36, borderRadius: 10, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  appbarTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.primary },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  greeting: { backgroundColor: Colors.white, paddingHorizontal: Spacing.md, paddingVertical: 16 },
  greetName: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.textDark },
  greetSub: { fontSize: FontSize.sm, color: Colors.textMid, marginTop: 4 },
  sectionDivider: { height: 8, backgroundColor: Colors.lightBg },
  sectionLabel: { paddingHorizontal: Spacing.md, paddingVertical: 10, fontSize: FontSize.xs, fontWeight: '700', color: Colors.textLight, letterSpacing: 0.8 },
  card: { flexDirection: 'row', alignItems: 'center', gap: 14, marginHorizontal: Spacing.md, marginBottom: 10, padding: 16, backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border },
  cardIcon: { width: 52, height: 52, borderRadius: 12, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  cardTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  cardSub: { fontSize: 11, color: Colors.textMid, marginTop: 3 },
  cardFuel: { fontSize: 10, color: Colors.textLight, marginTop: 3 },
  badge: { paddingHorizontal: 7, paddingVertical: 2, borderRadius: 5 },
  badgeText: { fontSize: 9, fontWeight: '700' },
  chevron: { fontSize: 20, color: Colors.textLight },
  captainBanner: { flexDirection: 'row', alignItems: 'center', gap: 14, marginHorizontal: Spacing.md, marginTop: 6, padding: 16, backgroundColor: Colors.dark, borderRadius: Radius.lg },
  bannerIcon: { width: 44, height: 44, borderRadius: 12, backgroundColor: 'rgba(29,158,117,0.18)', alignItems: 'center', justifyContent: 'center' },
  bannerTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.white },
  bannerSub: { fontSize: 11, color: Colors.textLight, marginTop: 3 },
});
