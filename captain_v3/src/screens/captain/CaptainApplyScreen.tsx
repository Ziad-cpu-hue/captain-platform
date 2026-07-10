import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput, Alert, ActivityIndicator, Image } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import * as ImagePicker from 'expo-image-picker';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { submitCaptainApplication, uploadDocument } from '../../services/firebase';
import { useAuthStore } from '../../store';
import { VehicleType, VEHICLE_ICONS } from '../../utils/pricing';

const DOCS = [
  { key: 'selfieWithFrontId', label: 'Selfie with Front ID', hint: 'Hold your ID next to your face', emoji: '🤳' },
  { key: 'selfieWithBackId', label: 'Selfie with Back ID', hint: 'Hold back of ID next to your face', emoji: '🤳' },
  { key: 'driversLicense', label: "Driver's License", hint: 'Clear photo of your license', emoji: '📄' },
  { key: 'carRegistration', label: 'Car Registration', hint: 'Official registration document', emoji: '📋' },
  { key: 'carWithPlate', label: 'Car with License Plate', hint: 'Photo showing the plate clearly', emoji: '🚗' },
] as const;

export default function CaptainApplyScreen() {
  const navigation = useNavigation<any>();
  const user = useAuthStore((s: any) => s.user);
  const [step, setStep] = useState(0);
  const [phone, setPhone] = useState('');
  const [vehicleType, setVehicleType] = useState<VehicleType>('car');
  const [photos, setPhotos] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  async function pickPhoto(key: string) {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      // Try gallery as fallback
      const galleryResult = await ImagePicker.launchImageLibraryAsync({ quality: 0.8 });
      if (!galleryResult.canceled) {
        setPhotos(p => ({ ...p, [key]: galleryResult.assets[0].uri }));
      }
      return;
    }
    const result = await ImagePicker.launchCameraAsync({ quality: 0.8 });
    if (!result.canceled) setPhotos(p => ({ ...p, [key]: result.assets[0].uri }));
  }

  async function handleSubmit() {
    if (!user) return;
    try {
      setLoading(true);
      const uploaded: Record<string, string> = {};
      for (const doc of DOCS) {
        if (photos[doc.key]) {
          uploaded[doc.key] = await uploadDocument(photos[doc.key], `captain_docs/${user.uid}/${doc.key}`);
        } else {
          uploaded[doc.key] = 'pending_upload';
        }
      }
      await submitCaptainApplication(user.uid, {
        uid: user.uid,
        displayName: user.displayName,
        phone,
        vehicleType,
        ...uploaded,
      });
      Alert.alert('Application Submitted! 🎉', 'We will review your documents within 24 hours and notify you by push notification.', [
        { text: 'OK', onPress: () => navigation.goBack() },
      ]);
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setLoading(false);
    }
  }

  const STEP_LABELS = ['1 Personal', '2 Documents', '3 Review'];

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.appbar}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.appbarTitle}>Become a Captain</Text>
      </View>

      {/* Step tabs */}
      <View style={styles.stepTabs}>
        {STEP_LABELS.map((label, i) => (
          <View key={label} style={[styles.stepTab, i === step ? styles.stepTabActive : i < step ? styles.stepTabDone : styles.stepTabTodo]}>
            <Text style={[styles.stepTabText, i === step ? styles.stepTabTextActive : i < step ? styles.stepTabTextDone : styles.stepTabTextTodo]}>
              {i < step ? '✓ ' : ''}{label}
            </Text>
          </View>
        ))}
      </View>

      <ScrollView contentContainerStyle={{ padding: Spacing.md }}>
        {/* STEP 0 — Personal Info */}
        {step === 0 && (
          <View>
            <Text style={styles.stepDesc}>Tell us a bit about yourself and your vehicle.</Text>
            <View style={styles.field}>
              <Text style={styles.fieldLabel}>FULL NAME</Text>
              <View style={styles.fieldDisplay}><Text style={styles.fieldDisplayText}>{user?.displayName || 'Your Name'}</Text></View>
            </View>
            <View style={styles.field}>
              <Text style={styles.fieldLabel}>PHONE NUMBER</Text>
              <TextInput style={styles.fieldInput} value={phone} onChangeText={setPhone} placeholder="+20 1XX XXX XXXX" keyboardType="phone-pad" placeholderTextColor={Colors.textLight} />
            </View>
            <View style={styles.field}>
              <Text style={styles.fieldLabel}>VEHICLE TYPE</Text>
              <View style={styles.vehicleChips}>
                {(['car', 'motorcycle', 'truck'] as VehicleType[]).map(v => (
                  <TouchableOpacity key={v} style={[styles.vChip, vehicleType === v && styles.vChipActive]} onPress={() => setVehicleType(v)}>
                    <Text style={{ fontSize: 22 }}>{VEHICLE_ICONS[v]}</Text>
                    <Text style={[styles.vChipText, vehicleType === v && styles.vChipTextActive]}>
                      {v === 'car' ? 'Car' : v === 'motorcycle' ? 'Moto' : 'Truck'}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
            <TouchableOpacity
              style={styles.btn}
              onPress={() => { if (!phone.trim()) { Alert.alert('Please enter your phone number'); return; } setStep(1); }}
            >
              <Text style={styles.btnText}>Continue →</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* STEP 1 — Documents */}
        {step === 1 && (
          <View>
            <View style={styles.warningNote}>
              <Text style={styles.warningText}>📷  Take clear, well-lit photos. All 5 documents are required for review.</Text>
            </View>
            {DOCS.map(doc => (
              <TouchableOpacity key={doc.key} style={styles.docRow} onPress={() => pickPhoto(doc.key)} activeOpacity={0.7}>
                {photos[doc.key] ? (
                  <Image source={{ uri: photos[doc.key] }} style={styles.docThumbDone} />
                ) : (
                  <View style={styles.docThumb}><Text style={{ fontSize: 22 }}>{doc.emoji}</Text></View>
                )}
                <View style={{ flex: 1 }}>
                  <Text style={styles.docLabel}>{doc.label}</Text>
                  <Text style={[styles.docHint, photos[doc.key] && { color: Colors.primary }]}>
                    {photos[doc.key] ? '✓ Photo captured — tap to retake' : doc.hint}
                  </Text>
                </View>
                <Text style={{ fontSize: 18, color: photos[doc.key] ? Colors.primary : Colors.textLight }}>
                  {photos[doc.key] ? '✓' : '📷'}
                </Text>
              </TouchableOpacity>
            ))}
            <View style={styles.rowBtns}>
              <TouchableOpacity style={styles.btnSecondary} onPress={() => setStep(0)}>
                <Text style={styles.btnSecondaryText}>← Back</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.btn, { flex: 2 }]} onPress={() => setStep(2)}>
                <Text style={styles.btnText}>Continue →</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* STEP 2 — Review & Submit */}
        {step === 2 && (
          <View>
            <View style={styles.reviewCard}>
              <Text style={styles.reviewTitle}>Personal Information</Text>
              <Text style={styles.reviewItem}>👤  {user?.displayName}</Text>
              <Text style={styles.reviewItem}>📞  {phone}</Text>
              <Text style={styles.reviewItem}>{VEHICLE_ICONS[vehicleType]}  {vehicleType === 'car' ? 'Private Car' : vehicleType === 'motorcycle' ? 'Motorcycle' : 'Cargo Truck'}</Text>
            </View>
            <View style={styles.reviewCard}>
              <Text style={styles.reviewTitle}>Documents</Text>
              {DOCS.map(doc => (
                <Text key={doc.key} style={styles.reviewItem}>
                  {photos[doc.key] ? '✅' : '⏳'}  {doc.label}
                </Text>
              ))}
            </View>
            <View style={styles.infoNote}>
              <Text style={styles.infoText}>
                Your application will be reviewed within 24 hours. You'll receive a notification once approved. You can start earning immediately after approval!
              </Text>
            </View>
            <View style={styles.rowBtns}>
              <TouchableOpacity style={styles.btnSecondary} onPress={() => setStep(1)}>
                <Text style={styles.btnSecondaryText}>← Back</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.btn, { flex: 2 }]} onPress={handleSubmit} disabled={loading}>
                {loading ? <ActivityIndicator color={Colors.white} /> : <Text style={styles.btnText}>Submit Application 🚀</Text>}
              </TouchableOpacity>
            </View>
          </View>
        )}
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
  stepTabs: { flexDirection: 'row', marginHorizontal: Spacing.md, marginVertical: 14, borderRadius: Radius.md, overflow: 'hidden', borderWidth: 0.5, borderColor: Colors.border },
  stepTab: { flex: 1, paddingVertical: 10, alignItems: 'center' },
  stepTabActive: { backgroundColor: Colors.primary },
  stepTabDone: { backgroundColor: Colors.primaryLight },
  stepTabTodo: { backgroundColor: Colors.white },
  stepTabText: { fontSize: 10, fontWeight: '700' },
  stepTabTextActive: { color: Colors.white },
  stepTabTextDone: { color: Colors.primaryDark },
  stepTabTextTodo: { color: Colors.textLight },
  stepDesc: { fontSize: FontSize.sm, color: Colors.textMid, marginBottom: 16, lineHeight: 20 },
  field: { marginBottom: 16 },
  fieldLabel: { fontSize: FontSize.xs, fontWeight: '700', color: Colors.textLight, marginBottom: 6, letterSpacing: 0.5 },
  fieldDisplay: { padding: 13, borderRadius: Radius.md, borderWidth: 0.5, borderColor: Colors.border, backgroundColor: Colors.lightBg },
  fieldDisplayText: { fontSize: FontSize.md, color: Colors.textDark },
  fieldInput: { padding: 13, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white, fontSize: FontSize.md, color: Colors.textDark },
  vehicleChips: { flexDirection: 'row', gap: 10 },
  vChip: { flex: 1, paddingVertical: 14, borderRadius: Radius.md, borderWidth: 1.5, borderColor: Colors.border, alignItems: 'center', gap: 6, backgroundColor: Colors.white },
  vChipActive: { borderColor: Colors.primary, backgroundColor: Colors.primaryLight },
  vChipText: { fontSize: 11, fontWeight: '700', color: Colors.textMid },
  vChipTextActive: { color: Colors.primaryDark },
  warningNote: { backgroundColor: Colors.amberLight, borderRadius: Radius.md, borderWidth: 0.5, borderColor: '#EF9F2740', padding: 12, marginBottom: 14 },
  warningText: { fontSize: 11, color: Colors.amberDark, lineHeight: 17 },
  docRow: { flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: Colors.white, borderRadius: Radius.md, borderWidth: 0.5, borderColor: Colors.border, padding: 12, marginBottom: 8 },
  docThumb: { width: 48, height: 48, borderRadius: Radius.sm, backgroundColor: Colors.lightBg, borderWidth: 0.5, borderColor: Colors.border, alignItems: 'center', justifyContent: 'center' },
  docThumbDone: { width: 48, height: 48, borderRadius: Radius.sm },
  docLabel: { fontSize: FontSize.sm, fontWeight: '700', color: Colors.textDark },
  docHint: { fontSize: FontSize.xs, color: Colors.textLight, marginTop: 2 },
  rowBtns: { flexDirection: 'row', gap: 10, marginTop: 8 },
  btn: { backgroundColor: Colors.primary, borderRadius: Radius.md, padding: 14, alignItems: 'center' },
  btnText: { color: Colors.white, fontSize: FontSize.md, fontWeight: '700' },
  btnSecondary: { flex: 1, borderRadius: Radius.md, padding: 14, alignItems: 'center', borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white },
  btnSecondaryText: { color: Colors.textDark, fontSize: FontSize.md, fontWeight: '600' },
  reviewCard: { backgroundColor: Colors.white, borderRadius: Radius.lg, borderWidth: 0.5, borderColor: Colors.border, padding: Spacing.md, marginBottom: 12 },
  reviewTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark, marginBottom: 12 },
  reviewItem: { fontSize: FontSize.sm, color: Colors.textMid, marginBottom: 8, lineHeight: 20 },
  infoNote: { backgroundColor: Colors.primaryLight, borderRadius: Radius.md, padding: 14, marginBottom: 16 },
  infoText: { fontSize: 11, color: Colors.primaryDark, lineHeight: 18 },
});
