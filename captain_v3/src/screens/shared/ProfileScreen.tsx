import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { signOut } from '../../services/firebase';
import { useAuthStore } from '../../store';

export default function ProfileScreen() {
  const navigation = useNavigation<any>();
  const { user, setUser } = useAuthStore();

  async function handleSignOut() {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign Out', style: 'destructive', onPress: async () => {
          await signOut();
          setUser(null);
        },
      },
    ]);
  }

  const roleColors: Record<string, { bg: string; text: string }> = {
    customer: { bg: Colors.primaryLight, text: Colors.primaryDark },
    captain: { bg: Colors.amberLight, text: Colors.amberDark },
    admin: { bg: Colors.coralLight, text: Colors.coralDark },
  };
  const rc = roleColors[user?.role ?? 'customer'];

  const tiles = [
    ...(user?.role === 'customer' ? [{ icon: '⭐', label: 'Become a Captain', sub: 'Join our team and earn', onPress: () => navigation.navigate('CaptainApply'), danger: false }] : []),
    { icon: '📋', label: 'Order History', sub: 'View your past trips', onPress: () => navigation.navigate('History'), danger: false },
    { icon: '🎧', label: 'Contact Support', sub: 'We are here to help', onPress: () => navigation.navigate('Chat', { threadId: 'support', title: 'Support' }), danger: false },
    { icon: '🔒', label: 'Privacy Policy', sub: 'How we use your data', onPress: () => {}, danger: false },
    { icon: '🚪', label: 'Sign Out', sub: 'See you next time!', onPress: handleSignOut, danger: true },
  ];

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.appbar}>
        <Text style={styles.appbarTitle}>Profile</Text>
      </View>

      <ScrollView>
        {/* Profile header */}
        <View style={styles.profileHeader}>
          <View style={styles.avatar}>
            <Text style={{ fontSize: 32 }}>👤</Text>
          </View>
          <Text style={styles.name}>{user?.displayName || 'User'}</Text>
          <Text style={styles.email}>{user?.email || 'demo@captain.eg'}</Text>
          <View style={[styles.roleBadge, { backgroundColor: rc.bg }]}>
            <Text style={[styles.roleText, { color: rc.text }]}>
              {user?.role?.toUpperCase() || 'CUSTOMER'}
            </Text>
          </View>
        </View>

        {/* Stats row */}
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>0</Text>
            <Text style={styles.statLabel}>Trips</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statValue}>⭐ 5.0</Text>
            <Text style={styles.statLabel}>Rating</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statValue}>0 EGP</Text>
            <Text style={styles.statLabel}>Saved</Text>
          </View>
        </View>

        {/* Tiles */}
        <View style={{ padding: Spacing.md, gap: 8 }}>
          {tiles.map(tile => (
            <TouchableOpacity key={tile.label} style={styles.tile} onPress={tile.onPress} activeOpacity={0.7}>
              <View style={[styles.tileIconBox, tile.danger && styles.tileIconBoxDanger]}>
                <Text style={{ fontSize: 18 }}>{tile.icon}</Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={[styles.tileLabel, tile.danger && styles.tileLabelDanger]}>{tile.label}</Text>
                <Text style={styles.tileSub}>{tile.sub}</Text>
              </View>
              <Text style={styles.chevron}>›</Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.version}>CapTain v1.0.0 · Built with ❤️ in Egypt</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  appbar: { paddingHorizontal: Spacing.md, paddingVertical: 16, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  appbarTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.textDark },
  profileHeader: { alignItems: 'center', paddingVertical: 28, paddingHorizontal: Spacing.md, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  avatar: { width: 72, height: 72, borderRadius: 36, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  name: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.textDark },
  email: { fontSize: FontSize.sm, color: Colors.textMid, marginTop: 4 },
  roleBadge: { marginTop: 10, paddingHorizontal: 16, paddingVertical: 5, borderRadius: Radius.full },
  roleText: { fontSize: FontSize.xs, fontWeight: '700', letterSpacing: 0.8 },
  statsRow: { flexDirection: 'row', backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border, paddingVertical: 16 },
  statItem: { flex: 1, alignItems: 'center' },
  statValue: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  statLabel: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 3 },
  statDivider: { width: 0.5, backgroundColor: Colors.border, marginVertical: 4 },
  tile: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 14, backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border },
  tileIconBox: { width: 42, height: 42, borderRadius: 10, backgroundColor: Colors.lightBg, alignItems: 'center', justifyContent: 'center' },
  tileIconBoxDanger: { backgroundColor: Colors.coralLight },
  tileLabel: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  tileLabelDanger: { color: Colors.error },
  tileSub: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 2 },
  chevron: { fontSize: 20, color: Colors.textLight },
  version: { textAlign: 'center', color: Colors.textLight, fontSize: FontSize.xs, paddingVertical: 24 },
});
