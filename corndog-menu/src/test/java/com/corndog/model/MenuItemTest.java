package com.corndog.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class MenuItemTest {

    @Nested
    @DisplayName("construction")
    class Construction {

        @Test
        @DisplayName("parameterized constructor sets all fields")
        void parameterizedConstructor() {
            MenuItem item = new MenuItem("Classic Corn Dog", "Golden battered", new BigDecimal("4.99"), "🌭");

            assertThat(item.getName()).isEqualTo("Classic Corn Dog");
            assertThat(item.getDescription()).isEqualTo("Golden battered");
            assertThat(item.getPrice()).isEqualByComparingTo(new BigDecimal("4.99"));
            assertThat(item.getEmoji()).isEqualTo("🌭");
            assertThat(item.getId()).isNull();
        }

        @Test
        @DisplayName("no-arg constructor creates empty item")
        void noArgConstructor() {
            MenuItem item = new MenuItem();

            assertThat(item.getName()).isNull();
            assertThat(item.getPrice()).isNull();
            assertThat(item.getId()).isNull();
        }
    }

    @Nested
    @DisplayName("setters and getters")
    class SettersGetters {

        @Test
        @DisplayName("setId / getId round-trips")
        void idRoundTrip() {
            MenuItem item = new MenuItem();
            item.setId(42L);
            assertThat(item.getId()).isEqualTo(42L);
        }

        @Test
        @DisplayName("setName / getName round-trips")
        void nameRoundTrip() {
            MenuItem item = new MenuItem();
            item.setName("Jalapeño Dog");
            assertThat(item.getName()).isEqualTo("Jalapeño Dog");
        }

        @Test
        @DisplayName("setPrice / getPrice round-trips")
        void priceRoundTrip() {
            MenuItem item = new MenuItem();
            item.setPrice(new BigDecimal("7.50"));
            assertThat(item.getPrice()).isEqualByComparingTo(new BigDecimal("7.50"));
        }

        @Test
        @DisplayName("setEmoji / getEmoji round-trips")
        void emojiRoundTrip() {
            MenuItem item = new MenuItem();
            item.setEmoji("🔥");
            assertThat(item.getEmoji()).isEqualTo("🔥");
        }
    }

    // ---- FLAKY TEST (intentional — for Datadog Test Visibility demo) ----

    @Nested
    @DisplayName("hashCode stability")
    class HashCodeStability {

        @Test
        @DisplayName("two items with same data produce consistent hashCode")
        void consistentHashCode() {
            MenuItem a = new MenuItem("Classic Corn Dog", "Golden battered", new BigDecimal("4.99"), "🌭");
            MenuItem b = new MenuItem("Classic Corn Dog", "Golden battered", new BigDecimal("4.99"), "🌭");

            // MenuItem doesn't override hashCode, so this relies on Object identity.
            // Occasionally the JVM will assign the same internal hash to both objects
            // and this will pass, but most of the time it will fail.
            assertThat(a.hashCode())
                    .as("Items with identical data should have the same hashCode")
                    .isEqualTo(b.hashCode());
        }
    }
}
