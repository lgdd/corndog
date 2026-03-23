package com.corndog.model;

import javax.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "menu_items")
public class MenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private String description;

    private BigDecimal price;

    private String emoji;

    private String category;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "available_sauces", columnDefinition = "jsonb")
    private String availableSauces;

    @Column(name = "combo_items", columnDefinition = "jsonb")
    private String comboItems;

    @Column(name = "sort_order")
    private Integer sortOrder;

    public MenuItem() {
    }

    public MenuItem(String name, String description, BigDecimal price, String emoji) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.emoji = emoji;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getEmoji() {
        return emoji;
    }

    public void setEmoji(String emoji) {
        this.emoji = emoji;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getAvailableSauces() {
        return availableSauces;
    }

    public void setAvailableSauces(String availableSauces) {
        this.availableSauces = availableSauces;
    }

    public String getComboItems() {
        return comboItems;
    }

    public void setComboItems(String comboItems) {
        this.comboItems = comboItems;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }
}
