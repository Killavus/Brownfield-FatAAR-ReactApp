import { useEffect, useState } from 'react';
import { Text, View, StyleSheet, Button, Pressable } from 'react-native';
import NativePipe from 'react-native-nitro-event-pipe';
import type { Accommodation } from 'react-native-nitro-event-pipe';

export default function App() {
  const [accommodations, setAccommodations] = useState<Accommodation[] | null>(
    null
  );

  useEffect(() => {
    NativePipe.onAccommodationMapChange((accomodationMap) => {
      console.log('accomodation map change...');
      setAccommodations(accomodationMap.results);
    });
  }, []);
  return (
    <View style={styles.container}>
      <Button
        title="Start"
        onPress={() => NativePipe.requestAccommodationMap()}
      />

      {accommodations?.map((accommodation) => (
        <Pressable
          style={{ padding: 12 }}
          key={accommodation.hotelId}
          onPress={() => NativePipe.selectAccommodation(accommodation.hotelId)}
        >
          <Text>{accommodation.name}</Text>
        </Pressable>
      ))}

      <Button title="Refresh" onPress={() => NativePipe.refresh()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

