import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, FontSize } from '../../theme';
import { onAuthStateChanged } from '../../services/firebase';
import { useAuthStore } from '../../store';

export default function SplashScreen() {
  const { setUser, setLoading } = useAuthStore();

  useEffect(() => {
    // Always resolves — even without Firebase
    const unsub = onAuthStateChanged((user: any) => {
      setUser(user);
      setLoading(false);
    });
    // Fallback: if Firebase takes too long, show login after 3 seconds
    const timeout = setTimeout(() => setLoading(false), 3000);
    return () => { unsub(); clearTimeout(timeout); };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.logoBox}>
        <Text style={styles.logoIcon}>🚗</Text>
      </View>
      <Text style={styles.title}>CapTain</Text>
      <Text style={styles.subtitle}>Your ride, your cargo, your way</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.dark, alignItems: 'center', justifyContent: 'center', gap: 12 },
  logoBox: { width: 80, height: 80, borderRadius: 24, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center', marginBottom: 8 },
  logoIcon: { fontSize: 40 },
  title: { fontSize: FontSize.xxxl, fontWeight: '700', color: Colors.white, letterSpacing: -1 },
  subtitle: { fontSize: FontSize.sm, color: 'rgba(255,255,255,0.5)' },
});
