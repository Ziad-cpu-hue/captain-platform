import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Colors, FontSize, Spacing, Radius } from '../../theme';
import { signInDemo, firebaseReady } from '../../services/firebase';
import { useAuthStore } from '../../store';

export default function LoginScreen() {
  const [loading, setLoading] = useState(false);
  const setUser = useAuthStore((s: any) => s.setUser);

  async function handleDemoLogin(role: 'customer' | 'captain') {
    setLoading(true);
    await new Promise(r => setTimeout(r, 800)); // small delay for feel
    const user = signInDemo(role);
    setUser(user);
    setLoading(false);
  }

  async function handleGoogleSignIn() {
    if (!firebaseReady) {
      Alert.alert(
        'Firebase Not Configured',
        'Google Sign-In requires Firebase setup.\n\nFor now, use Demo Mode to test all app screens.',
        [{ text: 'OK' }]
      );
      return;
    }
    // Real Google Sign-In when Firebase is configured
    Alert.alert('Coming soon', 'Add your Firebase config to enable Google Sign-In');
  }

  return (
    <View style={styles.container}>
      <View style={styles.circle1} />
      <View style={styles.circle2} />
      <SafeAreaView style={styles.inner}>
        {/* Logo */}
        <View style={styles.logoBox}>
          <Text style={styles.logoIcon}>🚗</Text>
        </View>
        <Text style={styles.title}>CapTain</Text>
        <Text style={styles.subtitle}>Your ride, your cargo, your way</Text>

        {/* Service pills */}
        <View style={styles.pillRow}>
          {[['🚗', 'Private Cars'], ['🏍️', 'Motorcycles'], ['🚚', 'Cargo Trucks']].map(([icon, label]) => (
            <View key={label} style={styles.pill}>
              <Text style={{ fontSize: 13 }}>{icon}</Text>
              <Text style={styles.pillText}>{label}</Text>
            </View>
          ))}
        </View>

        {/* Google Sign-In */}
        <TouchableOpacity style={styles.googleBtn} onPress={handleGoogleSignIn} disabled={loading}>
          <View style={styles.googleG}><Text style={{ color: Colors.white, fontSize: 11, fontWeight: '700' }}>G</Text></View>
          <Text style={styles.googleBtnText}>Continue with Google</Text>
        </TouchableOpacity>

        {/* Demo Mode buttons */}
        <View style={styles.demoSection}>
          <Text style={styles.demoLabel}>— Demo Mode —</Text>
          <View style={styles.demoRow}>
            <TouchableOpacity style={styles.demoBtn} onPress={() => handleDemoLogin('customer')} disabled={loading}>
              {loading ? <ActivityIndicator color={Colors.white} size="small" /> : <Text style={styles.demoBtnText}>👤 Customer Demo</Text>}
            </TouchableOpacity>
            <TouchableOpacity style={[styles.demoBtn, styles.demoBtnCaptain]} onPress={() => handleDemoLogin('captain')} disabled={loading}>
              {loading ? <ActivityIndicator color={Colors.white} size="small" /> : <Text style={styles.demoBtnText}>🚗 Captain Demo</Text>}
            </TouchableOpacity>
          </View>
        </View>

        <Text style={styles.terms}>By continuing you agree to our{'\n'}Terms of Service and Privacy Policy.</Text>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.dark },
  circle1: { position: 'absolute', top: -60, right: -40, width: 200, height: 200, borderRadius: 100, backgroundColor: 'rgba(29,158,117,0.08)' },
  circle2: { position: 'absolute', bottom: -70, left: -50, width: 220, height: 220, borderRadius: 110, backgroundColor: 'rgba(29,158,117,0.05)' },
  inner: { flex: 1, alignItems: 'center', paddingHorizontal: Spacing.xl },
  logoBox: { width: 72, height: 72, borderRadius: 20, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center', marginTop: 50, marginBottom: 14 },
  logoIcon: { fontSize: 34 },
  title: { fontSize: FontSize.xxxl, fontWeight: '700', color: Colors.white, letterSpacing: -1 },
  subtitle: { fontSize: FontSize.sm, color: 'rgba(255,255,255,0.5)', marginTop: 6, marginBottom: 28 },
  pillRow: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 8, marginBottom: 32 },
  pill: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingVertical: 6, paddingHorizontal: 12, borderRadius: 100, backgroundColor: 'rgba(255,255,255,0.07)', borderWidth: 0.5, borderColor: 'rgba(255,255,255,0.12)' },
  pillText: { color: Colors.white, fontSize: FontSize.sm, fontWeight: '600' },
  googleBtn: { width: '100%', paddingVertical: 14, backgroundColor: Colors.white, borderRadius: Radius.lg, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, marginBottom: 20 },
  googleG: { width: 20, height: 20, borderRadius: 10, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center' },
  googleBtnText: { color: Colors.dark, fontSize: FontSize.md, fontWeight: '700' },
  demoSection: { width: '100%', alignItems: 'center', gap: 10 },
  demoLabel: { fontSize: FontSize.xs, color: 'rgba(255,255,255,0.3)', letterSpacing: 1 },
  demoRow: { flexDirection: 'row', gap: 10, width: '100%' },
  demoBtn: { flex: 1, paddingVertical: 12, backgroundColor: 'rgba(29,158,117,0.3)', borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.primary, alignItems: 'center' },
  demoBtnCaptain: { backgroundColor: 'rgba(29,158,117,0.15)' },
  demoBtnText: { color: Colors.white, fontSize: FontSize.sm, fontWeight: '700' },
  terms: { fontSize: FontSize.xs, color: 'rgba(255,255,255,0.3)', textAlign: 'center', marginTop: 20, lineHeight: 18 },
});
