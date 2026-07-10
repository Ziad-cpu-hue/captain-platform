import React, { useCallback, useEffect, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import * as SplashScreen from 'expo-splash-screen';
import Navigation from './src/navigation';

// Keep splash screen visible while we initialize
SplashScreen.preventAutoHideAsync().catch(() => {});

export default function App() {
  const [appReady, setAppReady] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function prepare() {
      try {
        // Small delay for smooth splash transition
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (e: any) {
        setError(e.message);
      } finally {
        setAppReady(true);
      }
    }
    prepare();
  }, []);

  const onLayoutRootView = useCallback(async () => {
    if (appReady) {
      await SplashScreen.hideAsync().catch(() => {});
    }
  }, [appReady]);

  if (!appReady) {
    return null;
  }

  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorIcon}>⚠️</Text>
        <Text style={styles.errorText}>Something went wrong</Text>
        <Text style={styles.errorSub}>{error}</Text>
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }} onLayout={onLayoutRootView}>
      <SafeAreaProvider>
        <Navigation />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  errorContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#0A1628', padding: 24, gap: 12 },
  errorIcon: { fontSize: 48 },
  errorText: { fontSize: 18, fontWeight: '700', color: '#fff' },
  errorSub: { fontSize: 12, color: '#888', textAlign: 'center', lineHeight: 18 },
});
